// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {SeedClock} from "../../src/SeedClock.sol";
import {RoyaltyDistributor} from "../../src/RoyaltyDistributor.sol";
import {SeedClockDeploymentRehearsal} from "../../script/DeploySeedClock.s.sol";

contract MockIMD is ERC20 {
    constructor() ERC20("Test IMD", "IMD") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function destroy(address from, uint256 amount) external {
        _burn(from, amount);
    }
}

/// @dev A test model of the registry authorization boundary, not a production enforcement substitute.
contract MockTransferValidator {
    error UnauthorizedTransfer();

    mapping(address => mapping(address => mapping(uint256 => bool))) public authorized;

    function authorize(address collection, address operator, uint256 tokenId, bool value) external {
        authorized[collection][operator][tokenId] = value;
    }

    function validateTransfer(address caller, address from, address, uint256 id) external view {
        if (caller != from && !authorized[msg.sender][caller][id]) revert UnauthorizedTransfer();
    }
}

contract CallbackWallet is IERC721Receiver {
    SeedClock public immutable clock;
    RoyaltyDistributor public immutable distributor;
    bool public rejectNFT;
    bool public rejectETH;
    bool public attackMint;
    bool public attackClaim;
    bool public attempted;
    bool public reentered;

    constructor(SeedClock clock_, RoyaltyDistributor distributor_) {
        clock = clock_;
        distributor = distributor_;
    }

    function configure(bool rejectNFT_, bool rejectETH_, bool attackMint_, bool attackClaim_) external {
        rejectNFT = rejectNFT_;
        rejectETH = rejectETH_;
        attackMint = attackMint_;
        attackClaim = attackClaim_;
    }

    function mint(uint256 n) external {
        clock.mint(n);
    }

    function claim() external {
        distributor.claim();
    }

    function claimTo(address payable to) external {
        distributor.claimTo(address(0), to);
    }

    function move(address to, uint256 id) external {
        clock.transferFrom(address(this), to, id);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        require(!rejectNFT, "reject NFT");
        if (attackMint) {
            attempted = true;
            (reentered,) = address(clock).call(abi.encodeCall(clock.mint, (5)));
        }
        require(distributor.shares(address(this)) == clock.balanceOf(address(this)), "callback shares");
        require(distributor.totalShares() == clock.totalSupply(), "callback supply");
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {
        require(!rejectETH, "reject ETH");
        if (attackClaim) {
            attempted = true;
            (reentered,) = address(distributor).call(abi.encodeWithSignature("claim()"));
        }
    }
}

abstract contract SeedClockFixture is Test {
    SeedClock internal clock;
    RoyaltyDistributor internal distributor;
    MockIMD internal imd;
    MockTransferValidator internal validator;
    address internal treasury = makeAddr("treasury");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
    address internal operator = makeAddr("operator");

    function setUp() public virtual {
        SeedClockDeploymentRehearsal deployment = new SeedClockDeploymentRehearsal();
        (distributor, clock) =
            deployment.deploy(treasury, type(RoyaltyDistributor).creationCode, type(SeedClock).creationCode);
        MockIMD imdImplementation = new MockIMD();
        vm.etch(clock.IMD(), address(imdImplementation).code);
        imd = MockIMD(clock.IMD());
        MockTransferValidator validatorImplementation = new MockTransferValidator();
        vm.etch(clock.TRANSFER_VALIDATOR(), address(validatorImplementation).code);
        validator = MockTransferValidator(clock.TRANSFER_VALIDATOR());
        vm.deal(address(this), 1_000_000 ether);
    }

    function eligible(address wallet) internal {
        imd.mint(wallet, 1 ether);
    }

    function mintAs(address wallet, uint256 amount) internal {
        eligible(wallet);
        vm.prank(wallet);
        clock.mint(amount);
    }

    function pay(uint256 amount) internal {
        (bool ok,) = address(distributor).call{value: amount}("");
        assertTrue(ok);
    }

    function move(address from, address to, uint256 id) internal {
        vm.prank(from);
        clock.transferFrom(from, to, id);
    }

    receive() external payable {}
}
