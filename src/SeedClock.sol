// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ICreatorToken, ITransferValidator} from "./interfaces/ICreatorToken.sol";
import {IRoyaltyDistributor} from "./interfaces/IRoyaltyDistributor.sol";
import {SeedData} from "./art/SeedData.sol";
import {SeedArt} from "./art/SeedArt.sol";

/// @title SeedClock / SCLOCK — immutable, open, free IMD-holder mint.
/// @notice ERC721-C compatible: every secondary transfer invokes OpenSea's canonical strict validator.
/// Its authorized Seaport zone verifies the marketplace's royalty attestation. The collection itself
/// fixes ERC2981 to 690 bps and cannot disable validation or redirect royalties. Direct owner gifts
/// follow the registry policy; no ERC721 can discover payments made outside a marketplace order.
contract SeedClock is ERC721, IERC2981, ICreatorToken, ReentrancyGuard {
    error ZeroAddress();
    error InvalidQuantity();
    error WalletLimit();
    error SoldOut();
    error IMDRequired();
    error IMDUnavailable();
    error ValidatorUnavailable();
    error RoyaltiesArePermanent();

    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant TREASURY_SUPPLY = 55;
    uint256 public constant MAX_PER_WALLET = 5;
    uint96 public constant ROYALTY_BPS = 690;
    // Mainnet IMD decimals() = 18; this threshold is one whole IMD, not one raw unit.
    address public constant IMD = 0xD34a99Bc0f67aE1bbd63C660e6d0b0dd03E263B7;
    uint256 public constant MIN_IMD_BALANCE = 1 ether;
    // Official OpenSea StrictAuthorizedTransferSecurityRegistry, Ethereum mainnet.
    address public constant TRANSFER_VALIDATOR = 0xA000027A9B2802E1ddf7000061001e5c005A0000;

    address public immutable treasury;
    address public immutable distributor;
    uint256 public totalSupply;
    mapping(address wallet => uint256) public publicMinted;
    bool private _constructing = true;

    event PublicMint(address indexed wallet, uint256 indexed firstTokenId, uint256 quantity);

    /// @dev Deploy directly after RoyaltyDistributor in one atomic transaction. Treasury receives
    /// ordinary _mint, without external ERC721Receiver calls, so the pairing window is not reentrant.
    constructor(address treasury_, address distributor_) ERC721("SeedClock", "SCLOCK") {
        if (treasury_ == address(0) || distributor_ == address(0)) revert ZeroAddress();
        treasury = treasury_;
        distributor = distributor_;
        IRoyaltyDistributor(distributor_).bindCollection(treasury_, msg.sender);
        for (uint256 id = 1; id <= TREASURY_SUPPLY; ++id) {
            _mint(treasury_, id);
        }
        totalSupply = TREASURY_SUPPLY;
        _constructing = false;
        emit TransferValidatorUpdated(address(0), TRANSFER_VALIDATOR);
    }

    /// @notice Always open, free, nonpayable. The lifetime public mint allowance does not reset on transfer.
    function mint(uint256 quantity) external nonReentrant {
        if (quantity == 0 || quantity > MAX_PER_WALLET) revert InvalidQuantity();
        if (publicMinted[msg.sender] + quantity > MAX_PER_WALLET) revert WalletLimit();
        if (totalSupply + quantity > MAX_SUPPLY) revert SoldOut();
        if (IMD.code.length == 0) revert IMDUnavailable();
        if (IERC20(IMD).balanceOf(msg.sender) < MIN_IMD_BALANCE) revert IMDRequired();
        publicMinted[msg.sender] += quantity;
        uint256 first = totalSupply + 1;
        // Supply advances per token so receiver callbacks never observe nonexistent issued tokens.
        for (uint256 id = first; id < first + quantity; ++id) {
            ++totalSupply;
            _safeMint(msg.sender, id);
        }
        emit PublicMint(msg.sender, first, quantity);
    }

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (distributor, Math.mulDiv(salePrice, ROYALTY_BPS, 10_000));
    }

    function royaltyRecipient() external view returns (address) {
        return distributor;
    }

    function royaltyConfiguration()
        external
        view
        returns (address recipient, address distributorAddress, uint96 bps)
    {
        return (distributor, distributor, ROYALTY_BPS);
    }

    function getTransferValidator() external pure override returns (address) {
        return TRANSFER_VALIDATOR;
    }

    function getTransferValidationFunction() external pure override returns (bytes4, bool) {
        return (ITransferValidator.validateTransfer.selector, true);
    }

    /// @notice Present for ERC721-C discovery; no caller, including the treasury, can weaken enforcement.
    function setTransferValidator(address) external pure override {
        revert RoyaltiesArePermanent();
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || interfaceId == type(ICreatorToken).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return SeedArt.tokenURI(tokenId);
    }

    /// @notice Preview derivation for every valid collection ID, including tokens not minted yet.
    function seedData(uint256 tokenId) external pure returns (SeedData.Data memory) {
        return SeedData.derive(tokenId);
    }

    function artTraits(uint256 tokenId) external pure returns (SeedArt.Traits memory) {
        return SeedArt.traits(SeedData.derive(tokenId).artSeed);
    }

    function contractURI() external view returns (string memory) {
        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string.concat(
                        '{"name":"SeedClock","description":"5555 on-chain animated clocks. Free for IMD holders.",'
                        '"seller_fee_basis_points":690,"fee_recipient":"',
                        Strings.toHexString(distributor),
                        '"}'
                    )
                )
            )
        );
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address from) {
        from = _ownerOf(tokenId);
        // Check authorization before the external validator. The base checks again when it updates.
        if (auth != address(0)) _checkAuthorized(from, auth, tokenId);
        if (from != address(0)) {
            if (TRANSFER_VALIDATOR.code.length == 0) revert ValidatorUnavailable();
            ITransferValidator(TRANSFER_VALIDATOR).validateTransfer(msg.sender, from, to, tokenId);
        }
        if (!_constructing) IRoyaltyDistributor(distributor).updateShares(from, to, tokenId);
        return super._update(to, tokenId, auth);
    }
}
