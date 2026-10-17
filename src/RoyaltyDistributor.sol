// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title SeedClock holder royalties, without an owner or a withdrawal administrator.
/// @notice ETH snapshots on receipt. Standard ERC20 royalties snapshot when anyone calls syncToken.
/// Claims are paginated (at most 64 receipts) so receipts can never make a claim uncallable.
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

    event CollectionBound(address indexed collection, address indexed treasury);
    event RoyaltyReceived(address indexed asset, uint256 amount, uint64 revision, uint256 receipt);
    event RoyaltyClaimed(address indexed asset, address indexed holder, address indexed to, uint256 amount);

    uint256 public constant MAX_CLAIM_RECEIPTS = 64;
    uint256 private constant BINDING_SLOT = uint256(keccak256("SeedClock.binding.v1"));

    address public immutable treasury;
    address private immutable deploymentCaller;
    address public collection;
    address public firstTokenOwner;
    uint256 public totalShares;
    uint64 public revision;

    struct Checkpoint {
        uint64 revision;
        uint192 shares;
    }

    struct Receipt {
        uint64 revision;
        uint256 perToken;
    }

    mapping(address holder => uint256) public shares;
    mapping(address holder => Checkpoint[]) private _history;
    mapping(address asset => Receipt[]) private _receipts;
    // address(0) is the native ETH asset identifier, never a recipient or deployment placeholder.
    mapping(address asset => uint256) public accountedBalance;
    mapping(address asset => uint256) public totalReceived;
    mapping(address asset => uint256) public totalClaimed;
    mapping(address asset => mapping(address holder => uint256)) public nextReceipt;
    mapping(address asset => mapping(address holder => uint256)) public roundingCredit;

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
        firstTokenOwner = treasury;
        shares[treasury] = 55;
        revision = 1;
        _checkpoint(treasury);
        emit CollectionBound(msg.sender, treasury);
        _syncNative();
    }

    /// @notice Called only by SeedClock, on every mint and transfer, before the ERC721 receiver hook.
    function updateShares(address from, address to, uint256 tokenId) external {
        if (msg.sender != collection) revert NotCollection();
        if (from == to) return;
        ++revision;
        if (from == address(0)) {
            ++totalShares;
        } else {
            --shares[from];
            _checkpoint(from);
        }
        ++shares[to];
        _checkpoint(to);
        if (tokenId == 1) firstTokenOwner = to;
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

    /// @notice Claim the caller's next 64 ETH receipts and all accumulated rounding credit.
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

    /// @return amount Entitlement in the next batch, including rounding credit.
    /// @return end The exclusive receipt index that this claim would process.
    function claimable(address asset, address holder) external view returns (uint256 amount, uint256 end) {
        return _pending(asset, holder);
    }

    function receiptCount(address asset) external view returns (uint256) {
        return _receipts[asset].length;
    }

    function receipt(address asset, uint256 index) external view returns (Receipt memory) {
        return _receipts[asset][index];
    }

    function sharesAt(address holder, uint64 atRevision) public view returns (uint256) {
        Checkpoint[] storage history = _history[holder];
        uint256 low;
        uint256 high = history.length;
        while (low < high) {
            uint256 mid = (low + high) / 2;
            if (history[mid].revision > atRevision) high = mid;
            else low = mid + 1;
        }
        return low == 0 ? 0 : history[low - 1].shares;
    }

    function _checkpoint(address holder) private {
        _history[holder].push(Checkpoint(revision, uint192(shares[holder])));
    }

    function _syncNative() private {
        _record(address(0), address(this).balance - accountedBalance[address(0)]);
    }

    function _record(address asset, uint256 amount) private {
        if (amount == 0) return;
        accountedBalance[asset] += amount;
        totalReceived[asset] += amount;
        uint256 perToken = amount / totalShares;
        // Allocate indivisible dust (< one wei per minted token) to the holder of token 1 at receipt.
        // Every unit is claimable; nothing accumulates for an administrator. Sub-share dust receipts
        // do not grow the receipt queue, so sending single wei cannot fill it with useless entries.
        roundingCredit[asset][firstTokenOwner] += amount % totalShares;
        uint256 index = _receipts[asset].length;
        if (perToken != 0) _receipts[asset].push(Receipt(revision, perToken));
        emit RoyaltyReceived(asset, amount, revision, index);
    }

    function _pending(address asset, address holder) private view returns (uint256 amount, uint256 end) {
        uint256 start = nextReceipt[asset][holder];
        uint256 length = _receipts[asset].length;
        end = start + MAX_CLAIM_RECEIPTS;
        if (end > length) end = length;
        amount = roundingCredit[asset][holder];
        for (uint256 i = start; i < end; ++i) {
            Receipt storage item = _receipts[asset][i];
            amount += item.perToken * sharesAt(holder, item.revision);
        }
    }

    function _claim(address asset, address holder, address payable to) private returns (uint256 amount) {
        if (to == address(0) || to == address(this)) revert InvalidReceiver();
        uint256 end;
        (amount, end) = _pending(asset, holder);
        if (amount == 0 && end == nextReceipt[asset][holder]) revert NothingToClaim();
        nextReceipt[asset][holder] = end;
        roundingCredit[asset][holder] = 0;
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
