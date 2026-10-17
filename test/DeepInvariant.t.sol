// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {SeedClockFixture, MockIMD, MockTransferValidator} from "./helpers/Fixtures.sol";
import {SeedClock} from "../src/SeedClock.sol";
import {RoyaltyDistributor} from "../src/RoyaltyDistributor.sol";

/// @dev Drives long sequences: receipts beyond one 64-receipt claim page, forced (unsynced) ETH that a
/// later payment bundles, operator transfers through the validator, and claims redirected with claimTo.
/// The entitlement model is computed from ERC721 balances at receipt time, independent of checkpoints.
contract DeepHandler is Test {
    SeedClock public immutable clock;
    RoyaltyDistributor public immutable distributor;
    MockTransferValidator public immutable validator;
    MockIMD public immutable currency;
    address[5] public actors;
    address public immutable operator;

    mapping(address => uint256) public nativeOwed;
    mapping(address => uint256) public tokenOwed;
    mapping(address => uint256) public nativeEarnedTotal;
    mapping(address => uint256) public nativeClaimedBy;
    uint256 public forcedUnsynced;
    // Remainder below one unit per share, carried into the asset's next receipt.
    uint256 public nativeCarry;
    uint256 public tokenCarry;
    uint256 public nativeIn;
    uint256 public nativeOut;
    uint256 public tokenIn;
    uint256 public tokenOut;
    uint256 public lastSupply;
    uint256 public maxReceipts;
    bool public supplyDecreased;

    constructor(
        SeedClock clock_,
        RoyaltyDistributor distributor_,
        MockTransferValidator validator_,
        address[5] memory actors_,
        address operator_
    ) {
        clock = clock_;
        distributor = distributor_;
        validator = validator_;
        actors = actors_;
        operator = operator_;
        currency = new MockIMD();
        for (uint256 i; i < 5; ++i) {
            MockIMD(clock.IMD()).mint(actors[i], 1 ether);
            vm.prank(actors[i]);
            clock.setApprovalForAll(operator, true);
        }
        lastSupply = clock.totalSupply();
    }

    function mint(uint256 who, uint256 count) external {
        address actor = actors[who % 5];
        uint256 used = clock.publicMinted(actor);
        if (used == 5) {
            vm.prank(actor);
            vm.expectRevert(SeedClock.WalletLimit.selector);
            clock.mint(1);
            return;
        }
        uint256 quantity = bound(count, 1, 5 - used);
        vm.prank(actor);
        clock.mint(quantity);
        _trackSupply();
    }

    function ownerTransfer(uint256 tokenSeed, uint256 who) external {
        uint256 id = bound(tokenSeed, 1, clock.totalSupply());
        address from = clock.ownerOf(id);
        vm.prank(from);
        clock.transferFrom(from, actors[who % 5], id);
    }

    function operatorTransfer(uint256 tokenSeed, uint256 who, bool authorized) external {
        uint256 id = bound(tokenSeed, 1, clock.totalSupply());
        address from = clock.ownerOf(id);
        address to = actors[who % 5];
        validator.authorize(address(clock), operator, id, authorized);
        vm.prank(operator);
        if (!authorized) vm.expectRevert(MockTransferValidator.UnauthorizedTransfer.selector);
        clock.safeTransferFrom(from, to, id);
        validator.authorize(address(clock), operator, id, false);
    }

    function payNative(uint256 amount) external {
        // Mix of dust (below totalShares) and real sale-sized royalties.
        amount = amount % 2 == 0 ? bound(amount, 0, 20_000) : bound(amount, 0, 50 ether);
        vm.deal(address(this), amount);
        uint256 bundled = amount + forcedUnsynced;
        forcedUnsynced = 0;
        _credit(bundled, true);
        nativeIn += bundled;
        (bool ok,) = address(distributor).call{value: amount}("");
        require(ok, "payment");
    }

    /// Many sale-sized receipts in a row, so a single holder's backlog spans several claim pages.
    function burstPay(uint256 count, uint256 size) external {
        count = bound(count, 1, 80);
        size = bound(size, 5555, 1 ether);
        for (uint256 i; i < count; ++i) {
            uint256 amount = size + i;
            vm.deal(address(this), amount);
            uint256 bundled = amount + forcedUnsynced;
            forcedUnsynced = 0;
            _credit(bundled, true);
            nativeIn += bundled;
            (bool ok,) = address(distributor).call{value: amount}("");
            require(ok, "payment");
        }
        if (distributor.receiptCount(address(0)) > maxReceipts) {
            maxReceipts = distributor.receiptCount(address(0));
        }
    }

    function forceNative(uint256 amount, bool syncNow) external {
        amount = bound(amount, 1, 5 ether);
        vm.deal(address(distributor), address(distributor).balance + amount);
        forcedUnsynced += amount;
        if (syncNow) {
            _credit(forcedUnsynced, true);
            nativeIn += forcedUnsynced;
            forcedUnsynced = 0;
            distributor.syncNative();
        }
    }

    function payToken(uint256 amount) external {
        amount = bound(amount, 0, 1e24);
        _credit(amount, false);
        tokenIn += amount;
        currency.mint(address(distributor), amount);
        distributor.syncToken(address(currency));
    }

    /// Drains every page for the actor, optionally paying a different address.
    function claimNative(uint256 who, uint256 dest, bool redirect) external {
        address holder = actors[who % 5];
        address payable to = payable(redirect ? actors[dest % 5] : holder);
        uint256 got;
        uint256 before = to.balance;
        for (uint256 page; page < 64; ++page) {
            vm.prank(holder);
            try distributor.claimTo(address(0), to) returns (uint256 amount) {
                got += amount;
            } catch (bytes memory reason) {
                assertEq(
                    bytes4(reason), RoyaltyDistributor.NothingToClaim.selector, "unexpected claim revert"
                );
                break;
            }
        }
        assertEq(got, nativeOwed[holder], "claimed differs from model");
        if (to != address(distributor)) assertEq(to.balance - before, got, "paid differs from returned");
        nativeOwed[holder] = 0;
        nativeClaimedBy[holder] += got;
        nativeOut += got;
        (uint256 rest, uint256 end) = distributor.claimable(address(0), holder);
        assertEq(rest, 0);
        assertEq(end, distributor.nextReceipt(address(0), holder));
        assertEq(end, distributor.receiptCount(address(0)));
    }

    function claimToken(uint256 who) external {
        address holder = actors[who % 5];
        uint256 got;
        for (uint256 page; page < 64; ++page) {
            try distributor.claimFor(address(currency), holder) returns (uint256 amount) {
                got += amount;
            } catch (bytes memory reason) {
                assertEq(
                    bytes4(reason), RoyaltyDistributor.NothingToClaim.selector, "unexpected claim revert"
                );
                break;
            }
        }
        assertEq(got, tokenOwed[holder], "token claim differs from model");
        tokenOwed[holder] = 0;
        tokenOut += got;
    }

    function _credit(uint256 amount, bool nativeAsset) private {
        if (amount == 0) return;
        uint256 supply = clock.totalSupply();
        uint256 pool = amount + (nativeAsset ? nativeCarry : tokenCarry);
        uint256 perToken = pool / supply;
        if (nativeAsset) nativeCarry = pool % supply;
        else tokenCarry = pool % supply;
        for (uint256 i; i < 5; ++i) {
            address actor = actors[i];
            uint256 earned = clock.balanceOf(actor) * perToken;
            if (nativeAsset) {
                nativeOwed[actor] += earned;
                nativeEarnedTotal[actor] += earned;
            } else {
                tokenOwed[actor] += earned;
            }
        }
    }

    function _trackSupply() private {
        uint256 supply = clock.totalSupply();
        if (supply < lastSupply) supplyDecreased = true;
        lastSupply = supply;
    }
}

contract DeepInvariantTest is SeedClockFixture {
    DeepHandler private handler;
    address[5] private actors;
    address private carol = makeAddr("carol");
    address private dave = makeAddr("dave");

    function setUp() public override {
        super.setUp();
        actors = [treasury, alice, bob, carol, dave];
        handler = new DeepHandler(clock, distributor, validator, actors, operator);
        bytes4[] memory selectors = new bytes4[](10);
        selectors[0] = handler.mint.selector;
        selectors[1] = handler.ownerTransfer.selector;
        selectors[2] = handler.operatorTransfer.selector;
        selectors[3] = handler.payNative.selector;
        selectors[4] = handler.payNative.selector; // weight payments so pages exceed 64 receipts
        selectors[5] = handler.forceNative.selector;
        selectors[6] = handler.payToken.selector;
        selectors[7] = handler.claimNative.selector;
        selectors[8] = handler.claimToken.selector;
        selectors[9] = handler.burstPay.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
        targetContract(address(handler));
    }

    /// forge-config: default.invariant.runs = 48
    /// forge-config: default.invariant.depth = 160
    function invariant_nativeBalanceCoversEveryOutstandingEntitlement() public view {
        uint256 owed;
        for (uint256 i; i < 5; ++i) {
            owed += handler.nativeOwed(actors[i]);
            assertLe(handler.nativeClaimedBy(actors[i]), handler.nativeEarnedTotal(actors[i]));
        }
        uint256 carry = handler.nativeCarry();
        assertEq(distributor.undistributed(address(0)), carry, "carry drift");
        assertLt(carry, clock.totalSupply(), "carry reached one unit per share");
        assertEq(distributor.accountedBalance(address(0)), owed + carry, "accounted != owed + carry");
        assertEq(
            address(distributor).balance,
            owed + carry + handler.forcedUnsynced(),
            "balance != owed + carry + unsynced"
        );
        assertEq(distributor.totalReceived(address(0)), handler.nativeIn());
        assertEq(distributor.totalClaimed(address(0)), handler.nativeOut());
        assertEq(
            distributor.totalReceived(address(0)),
            distributor.totalClaimed(address(0)) + distributor.accountedBalance(address(0))
        );
    }

    /// forge-config: default.invariant.runs = 48
    /// forge-config: default.invariant.depth = 160
    function invariant_tokenBalanceCoversEveryOutstandingEntitlement() public view {
        address currency = address(handler.currency());
        uint256 owed;
        for (uint256 i; i < 5; ++i) {
            owed += handler.tokenOwed(actors[i]);
        }
        uint256 carry = handler.tokenCarry();
        assertEq(distributor.undistributed(currency), carry);
        assertLt(carry, clock.totalSupply());
        assertEq(MockIMD(currency).balanceOf(address(distributor)), owed + carry);
        assertEq(distributor.accountedBalance(currency), owed + carry);
        assertEq(distributor.totalReceived(currency), handler.tokenIn());
        assertEq(distributor.totalClaimed(currency), handler.tokenOut());
    }

    /// forge-config: default.invariant.runs = 48
    /// forge-config: default.invariant.depth = 160
    function invariant_supplySharesAndConfigurationNeverDrift() public view {
        uint256 sum;
        for (uint256 i; i < 5; ++i) {
            uint256 balance = clock.balanceOf(actors[i]);
            assertEq(distributor.shares(actors[i]), balance);
            assertEq(distributor.sharesAt(actors[i], distributor.revision()), balance);
            assertLe(clock.publicMinted(actors[i]), 5);
            sum += balance;
        }
        uint256 supply = clock.totalSupply();
        assertEq(sum, supply);
        assertEq(distributor.totalShares(), supply);
        assertGe(supply, 55);
        assertLe(supply, 5555);
        assertFalse(handler.supplyDecreased());
        assertEq(distributor.collection(), address(clock));
        assertEq(clock.treasury(), treasury);
        assertEq(clock.distributor(), address(distributor));
        (address recipient, address dist, uint96 bps) = clock.royaltyConfiguration();
        assertEq(recipient, address(distributor));
        assertEq(dist, address(distributor));
        assertEq(bps, 690);
        assertEq(clock.getTransferValidator(), clock.TRANSFER_VALIDATOR());
    }
}
