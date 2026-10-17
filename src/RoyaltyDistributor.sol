// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title SeedClock holder royalties, without an owner or a withdrawal administrator.
/// @notice ETH snapshots on receipt. Standard ERC20 royalties snapshot when anyone calls syncToken;
/// mainnet WETH is also synced before every share change. Receipts store a running per-token total,
/// so a claim costs O(balance changes x log receipts), independent of how many receipts exist.
/// Claims are paginated (at most 64 balance segments) so no history can make a claim uncallable.
/// @dev ATOMIC DEPLOYMENT REQUIRED: deploy this, then SeedClock, in the SAME transaction.
/// The temporary binding window exists only in transient storage. The launching factory must not
/// make untrusted calls between these two CREATE/CREATE2 operations. SeedClock binds in its constructor,
/// before making any receiver callbacks (there are none in that constructor). No later transaction,
/// including a transaction from the deployer or treasury, can bind or replace the collection.
contract RoyaltyDistributor is ReentrancyGuard {
    using SafeERC20 for IERC20;

    error ZeroAddress();
    error NotCollection();
    error BindingClosed();
    error IncorrectDeployment();
    error NotBound();
    error NativeAsset();
    error NothingToClaim();
    error PaymentFailed();
    error UnsupportedBalanceDecrease();
    error InvalidReceiver();
    error ReceiptTooLarge();

    event CollectionBound(address indexed collection, address indexed treasury);
    // Field order keeps the topic hash free of 0xf2/0xf4/0xff bytes: via-IR may place it in a data
    // section, which bytecode opcode scans (including the launch floor) read as instructions.
    event RoyaltyReceived(address indexed asset, uint256 amount, uint256 receipt, uint64 revision);
    event RoyaltyClaimed(address indexed asset, address indexed holder, address indexed to, uint256 amount);

    /// @notice Maximum number of constant-balance segments one claim settles.
    uint256 public constant MAX_CLAIM_SEGMENTS = 64;
    /// @notice RoyaltyReceived index for an amount smaller than one unit per share (kept as carry).
    uint256 public constant NO_RECEIPT = type(uint256).max;
    /// @notice Canonical Ethereum mainnet WETH9, the currency of OpenSea offers.
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 private constant BINDING_SLOT = uint256(keccak256("SeedClock.binding.v1"));

    address public immutable treasury;
    address private immutable deploymentCaller;
    address public collection;
    uint256 public totalShares;
    uint64 public revision;

    struct Checkpoint {
        uint64 revision;
        uint192 shares;
    }

    struct Receipt {
        uint64 revision;
        // Sum of perToken over this and every earlier receipt of the asset.
        uint192 cumulative;
    }

    mapping(address holder => uint256) public shares;
    mapping(address holder => Checkpoint[]) private _history;
    mapping(address asset => Receipt[]) private _receipts;
    // address(0) is the native ETH asset identifier, never a recipient or deployment placeholder.
    mapping(address asset => uint256) public accountedBalance;
    mapping(address asset => uint256) public totalReceived;
    mapping(address asset => uint256) public totalClaimed;
    mapping(address asset => mapping(address holder => uint256)) public nextReceipt;
    // Remainder (< totalShares base units) carried into the asset's next receipt.
    mapping(address asset => uint256) public undistributed;

    constructor(address treasury_) {
        if (treasury_ == address(0)) revert ZeroAddress();
        treasury = treasury_;
        deploymentCaller = msg.sender;
        uint256 slot = BINDING_SLOT;
        assembly ("memory-safe") {
            tstore(slot, 1)
        }
    }

    /// @dev Constructor-only handshake in the trusted atomic deployment transaction. Not an initializer
    /// available after deployment: the transient capability expires at the transaction boundary.
    function bindCollection(address treasury_, address deploymentCaller_) external {
        uint256 slot = BINDING_SLOT;
        uint256 open;
        assembly ("memory-safe") {
            open := tload(slot)
        }
        if (open != 1 || collection != address(0)) revert BindingClosed();
        if (
            treasury_ != treasury || deploymentCaller_ != deploymentCaller || msg.sender.code.length != 0
                || msg.sender == deploymentCaller
        ) revert IncorrectDeployment();
        assembly ("memory-safe") {
            tstore(slot, 0)
        }
        collection = msg.sender;
        totalShares = 55;
        shares[treasury] = 55;
        revision = 1;
        _checkpoint(treasury);
        emit CollectionBound(msg.sender, treasury);
        _syncNative();
    }

    /// @notice Called only by SeedClock, on every mint and transfer, before the ERC721 receiver hook.
    /// WETH received since the last change is first apportioned to the holders of record.
    function updateShares(address from, address to, uint256) external {
        if (msg.sender != collection) revert NotCollection();
        if (from == to) return;
        _syncWeth();
        ++revision;
        if (from == address(0)) {
            ++totalShares;
        } else {
            --shares[from];
            _checkpoint(from);
        }
        ++shares[to];
        _checkpoint(to);
    }

    receive() external payable {
        // Counterfactual / pre-binding deposits wait for the initial 55 treasury shares.
        if (collection != address(0)) _syncNative();
    }

    /// @notice Also accounts for forcibly sent ETH, without an administrative sweep.
    function syncNative() external {
        if (collection == address(0)) revert NotBound();
        _syncNative();
    }

    /// @notice Snapshot unaccounted standard ERC20 receipts (including WETH). Anyone can call this.
    /// Negative rebases / balance-confiscating tokens are unsupported; they cannot affect other assets.
    function syncToken(address asset) external nonReentrant {
        if (collection == address(0)) revert NotBound();
        if (asset == address(0)) revert NativeAsset();
        uint256 balance = IERC20(asset).balanceOf(address(this));
        if (balance < accountedBalance[asset]) revert UnsupportedBalanceDecrease();
        _record(asset, balance - accountedBalance[asset]);
    }

    /// @notice Claim the caller's ETH entitlement (up to 64 balance segments per call).
    function claim() external nonReentrant returns (uint256) {
        return _claim(address(0), msg.sender, payable(msg.sender));
    }

    function claim(address asset) external nonReentrant returns (uint256) {
        return _claim(asset, msg.sender, payable(msg.sender));
    }

    /// @notice A rejecting receiver can choose a different destination for its OWN entitlement.
    function claimTo(address asset, address payable to) external nonReentrant returns (uint256) {
        return _claim(asset, msg.sender, to);
    }

    /// @notice Permissionless assistance; a caller can never redirect somebody else's entitlement.
    function claimFor(address asset, address holder) external nonReentrant returns (uint256) {
        return _claim(asset, holder, payable(holder));
    }

    function claimable(address holder) external view returns (uint256 amount) {
        (amount,) = _pending(address(0), holder);
    }

    /// @return amount Entitlement in the next batch.
    /// @return end The exclusive receipt index that this claim would process.
    function claimable(address asset, address holder) external view returns (uint256 amount, uint256 end) {
        return _pending(asset, holder);
    }

    function receiptCount(address asset) external view returns (uint256) {
        return _receipts[asset].length;
    }

    function receipt(address asset, uint256 index)
        external
        view
        returns (uint64 atRevision, uint256 perToken, uint256 cumulative)
    {
        Receipt[] storage list = _receipts[asset];
        atRevision = list[index].revision;
        cumulative = list[index].cumulative;
        perToken = cumulative - _cumulativeBefore(list, index);
    }

    function sharesAt(address holder, uint64 atRevision) public view returns (uint256) {
        Checkpoint[] storage history = _history[holder];
        uint256 applied = _checkpointsAtOrBefore(history, atRevision);
        return applied == 0 ? 0 : history[applied - 1].shares;
    }

    function _checkpoint(address holder) private {
        _history[holder].push(Checkpoint(revision, uint192(shares[holder])));
    }

    function _syncNative() private {
        _record(address(0), address(this).balance - accountedBalance[address(0)]);
    }

    /// @dev WETH9 has no callbacks and its balance only grows by transfers in, so this cannot revert
    /// or reenter. Without code (any chain but mainnet) it is skipped; syncToken still works.
    function _syncWeth() private {
        if (WETH.code.length == 0) return;
        uint256 balance = IERC20(WETH).balanceOf(address(this));
        uint256 accounted = accountedBalance[WETH];
        if (balance > accounted) _record(WETH, balance - accounted);
    }

    function _record(address asset, uint256 amount) private {
        if (amount == 0) return;
        accountedBalance[asset] += amount;
        totalReceived[asset] += amount;
        // The remainder (< one unit per share) is carried into the next receipt instead of being
        // credited to any one holder, so every receipt is split strictly per share. Amounts below one
        // unit per share only add to the carry and never grow the receipt list.
        uint256 pool = amount + undistributed[asset];
        uint256 perToken = pool / totalShares;
        undistributed[asset] = pool % totalShares;
        uint256 index = NO_RECEIPT;
        if (perToken != 0) {
            Receipt[] storage list = _receipts[asset];
            index = list.length;
            uint256 cumulative = _cumulativeBefore(list, index) + perToken;
            if (cumulative > type(uint192).max) revert ReceiptTooLarge();
            list.push(Receipt(revision, uint192(cumulative)));
        }
        emit RoyaltyReceived(asset, amount, index, revision);
    }

    /// @dev Walks the holder's constant-balance segments from the cursor: each segment pays
    /// shares * (running total at its end - running total at its start). Segment ends are found by
    /// binary search (receipt revisions never decrease), so receipts in which the holder had no shares,
    /// however many, cost one step.
    function _pending(address asset, address holder) private view returns (uint256 amount, uint256 end) {
        Receipt[] storage list = _receipts[asset];
        Checkpoint[] storage history = _history[holder];
        uint256 length = list.length;
        end = nextReceipt[asset][holder];
        uint256 base = _cumulativeBefore(list, end);
        for (uint256 step; step < MAX_CLAIM_SEGMENTS && end < length; ++step) {
            // Checkpoints at or before this receipt's revision; the last one is the balance it pays.
            uint256 applied = _checkpointsAtOrBefore(history, list[end].revision);
            uint256 segmentEnd = applied == history.length
                ? length
                : _firstReceiptFrom(list, history[applied].revision, end, length);
            uint256 top = _cumulativeBefore(list, segmentEnd);
            if (applied != 0) amount += uint256(history[applied - 1].shares) * (top - base);
            base = top;
            end = segmentEnd;
        }
    }

    function _cumulativeBefore(Receipt[] storage list, uint256 index) private view returns (uint256) {
        return index == 0 ? 0 : list[index - 1].cumulative;
    }

    function _checkpointsAtOrBefore(Checkpoint[] storage history, uint64 atRevision)
        private
        view
        returns (uint256 low)
    {
        uint256 high = history.length;
        while (low < high) {
            uint256 mid = (low + high) / 2;
            if (history[mid].revision > atRevision) high = mid;
            else low = mid + 1;
        }
    }

    /// @dev First index in [low, high) whose receipt revision is >= atRevision, else high.
    function _firstReceiptFrom(Receipt[] storage list, uint64 atRevision, uint256 low, uint256 high)
        private
        view
        returns (uint256)
    {
        while (low < high) {
            uint256 mid = (low + high) / 2;
            if (list[mid].revision < atRevision) low = mid + 1;
            else high = mid;
        }
        return low;
    }

    function _claim(address asset, address holder, address payable to) private returns (uint256 amount) {
        if (to == address(0) || to == address(this)) revert InvalidReceiver();
        uint256 end;
        (amount, end) = _pending(asset, holder);
        if (amount == 0 && end == nextReceipt[asset][holder]) revert NothingToClaim();
        nextReceipt[asset][holder] = end;
        if (amount == 0) return 0; // Let holders advance past receipts in which they had no shares.
        accountedBalance[asset] -= amount;
        totalClaimed[asset] += amount;
        emit RoyaltyClaimed(asset, holder, to, amount);
        if (asset == address(0)) {
            (bool ok,) = to.call{value: amount}("");
            if (!ok) revert PaymentFailed();
        } else {
            IERC20(asset).safeTransfer(to, amount);
        }
    }
}
