// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {SeedClockFixture, MockIMD} from "./helpers/Fixtures.sol";
import {SeedClock} from "../src/SeedClock.sol";
import {RoyaltyDistributor} from "../src/RoyaltyDistributor.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

/// @dev IMD stand-in whose balanceOf reverts, as a paused or broken token would.
contract RevertingIMD {
    function balanceOf(address) external pure returns (uint256) {
        revert("IMD paused");
    }
}

/// @dev IMD stand-in that returns nothing from balanceOf.
contract SilentIMD {
    fallback() external {}
}

/// @notice Boundary and failure-path tests written against the accepted implementation.
contract AdversarialTest is SeedClockFixture {
    address private carol = makeAddr("carol");

    // ---------------------------------------------------------------- mint eligibility and ordering

    function test_quantityIsValidatedBeforeAnyIMDLookup() public {
        // Ineligible caller still sees InvalidQuantity, so bad input never reaches the token.
        vm.etch(clock.IMD(), "");
        vm.startPrank(alice);
        vm.expectRevert(SeedClock.InvalidQuantity.selector);
        clock.mint(0);
        vm.expectRevert(SeedClock.InvalidQuantity.selector);
        clock.mint(type(uint256).max);
        vm.stopPrank();
    }

    function test_hugeQuantityCannotOverflowWalletOrSupplyChecks() public {
        eligible(alice);
        vm.prank(alice);
        vm.expectRevert(SeedClock.InvalidQuantity.selector);
        clock.mint(type(uint256).max - 3);
        assertEq(clock.totalSupply(), 55);
        assertEq(clock.publicMinted(alice), 0);
    }

    function test_revertingIMDBalanceOfFailsClosedWithoutState() public {
        vm.etch(clock.IMD(), address(new RevertingIMD()).code);
        vm.prank(alice);
        vm.expectRevert(bytes("IMD paused"));
        clock.mint(1);
        assertEq(clock.totalSupply(), 55);
        assertEq(clock.publicMinted(alice), 0);
        assertEq(distributor.totalShares(), 55);
    }

    function test_IMDReturningNoDataFailsClosed() public {
        vm.etch(clock.IMD(), address(new SilentIMD()).code);
        vm.prank(alice);
        vm.expectRevert();
        clock.mint(1);
        assertEq(clock.totalSupply(), 55);
    }

    function test_IMDOnlyCountsCallersOwnBalance() public {
        // A wallet funded with IMD cannot mint on behalf of another, and minted tokens go to caller.
        eligible(alice);
        vm.prank(bob);
        vm.expectRevert(SeedClock.IMDRequired.selector);
        clock.mint(1);
        vm.prank(alice);
        clock.mint(1);
        assertEq(clock.ownerOf(56), alice);
        assertEq(clock.balanceOf(bob), 0);
    }

    function test_walletLimitAcrossSeveralSmallMints() public {
        eligible(alice);
        for (uint256 i; i < 5; ++i) {
            vm.prank(alice);
            clock.mint(1);
        }
        vm.prank(alice);
        vm.expectRevert(SeedClock.WalletLimit.selector);
        clock.mint(1);
        assertEq(clock.publicMinted(alice), 5);
        assertEq(clock.balanceOf(alice), 5);
    }

    function test_walletLimitRejectsWholeBatchThatWouldCrossIt() public {
        mintAs(alice, 4);
        vm.prank(alice);
        vm.expectRevert(SeedClock.WalletLimit.selector);
        clock.mint(2);
        // No partial fill.
        assertEq(clock.balanceOf(alice), 4);
        vm.prank(alice);
        clock.mint(1);
        assertEq(clock.publicMinted(alice), 5);
    }

    function test_treasuryHasNoExtraAllowanceBeyondPublicFive() public {
        mintAs(treasury, 5);
        vm.prank(treasury);
        vm.expectRevert(SeedClock.WalletLimit.selector);
        clock.mint(1);
        assertEq(clock.balanceOf(treasury), 60);
        assertEq(clock.totalSupply(), 60);
    }

    function test_mintedIdsAreSequentialAcrossWallets() public {
        mintAs(alice, 2);
        mintAs(bob, 3);
        assertEq(clock.ownerOf(56), alice);
        assertEq(clock.ownerOf(57), alice);
        assertEq(clock.ownerOf(58), bob);
        assertEq(clock.ownerOf(60), bob);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, 61));
        clock.ownerOf(61);
    }

    // ---------------------------------------------------------------- supply cap boundary

    function test_lastTokensMintableExactlyAndBatchOverCapRejected() public {
        for (uint256 i; i < 1099; ++i) {
            mintAs(address(uint160(0x200000 + i)), 5);
        }
        assertEq(clock.totalSupply(), 5550);
        mintAs(alice, 3);
        assertEq(clock.totalSupply(), 5553);
        eligible(bob);
        vm.startPrank(bob);
        vm.expectRevert(SeedClock.SoldOut.selector);
        clock.mint(5);
        vm.expectRevert(SeedClock.SoldOut.selector);
        clock.mint(3);
        clock.mint(2);
        vm.expectRevert(SeedClock.SoldOut.selector);
        clock.mint(1);
        vm.stopPrank();
        assertEq(clock.totalSupply(), 5555);
        assertEq(clock.ownerOf(5555), bob);
        assertEq(clock.publicMinted(bob), 2);
        assertEq(distributor.totalShares(), 5555);
        // Treasury's 55 + public 5500.
        assertEq(clock.balanceOf(treasury), 55);
        // The wallet limit is checked before supply; within the limit, sold out is reported.
        vm.prank(alice);
        vm.expectRevert(SeedClock.WalletLimit.selector);
        clock.mint(3);
        vm.prank(alice);
        vm.expectRevert(SeedClock.SoldOut.selector);
        clock.mint(1);
    }

    // ---------------------------------------------------------------- ERC721-C / ERC2981 discovery

    function test_creatorTokenInterfaceIdMatchesLimitBreakConstant() public view {
        // Limit Break ICreatorToken (v3) id, as checked by OpenSea and Seaport 1.6 zones.
        assertTrue(clock.supportsInterface(0xad0d7f6c));
        assertTrue(clock.supportsInterface(0x2a55205a)); // ERC2981
        (bytes4 selector,) = clock.getTransferValidationFunction();
        assertEq(selector, bytes4(0xcaee23ea));
        assertEq(clock.getTransferValidator(), 0xA000027A9B2802E1ddf7000061001e5c005A0000);
    }

    function testFuzz_royaltyRecipientIsDistributorForAnyIdAndPrice(uint256 tokenId, uint256 price)
        public
        view
    {
        (address receiver, uint256 amount) = clock.royaltyInfo(tokenId, price);
        assertEq(receiver, address(distributor));
        assertEq(amount, price / 10_000 * 690 + price % 10_000 * 690 / 10_000);
    }

    function test_royaltyRoundsDownAtSmallPrices() public view {
        (, uint256 amount) = clock.royaltyInfo(1, 14);
        assertEq(amount, 0);
        (, amount) = clock.royaltyInfo(1, 15);
        assertEq(amount, 1);
        (, amount) = clock.royaltyInfo(1, 10_000);
        assertEq(amount, 690);
    }

    function test_setTransferValidatorRevertsForEveryCaller() public {
        address[3] memory callers = [treasury, address(distributor), address(this)];
        for (uint256 i; i < 3; ++i) {
            vm.prank(callers[i]);
            vm.expectRevert(SeedClock.RoyaltiesArePermanent.selector);
            clock.setTransferValidator(address(1));
        }
        assertEq(clock.getTransferValidator(), clock.TRANSFER_VALIDATOR());
    }

    // ---------------------------------------------------------------- distributor failure paths

    function test_freshHolderWithNoReceiptsCannotClaim() public {
        vm.prank(alice);
        vm.expectRevert(RoyaltyDistributor.NothingToClaim.selector);
        distributor.claim();
        vm.prank(treasury);
        vm.expectRevert(RoyaltyDistributor.NothingToClaim.selector);
        distributor.claim();
        MockIMD currency = new MockIMD();
        vm.expectRevert(RoyaltyDistributor.NothingToClaim.selector);
        distributor.claimFor(address(currency), treasury);
    }

    function test_secondClaimOfSameReceiptReverts() public {
        pay(55 ether);
        distributor.claimFor(address(0), treasury);
        vm.expectRevert(RoyaltyDistributor.NothingToClaim.selector);
        distributor.claimFor(address(0), treasury);
        vm.prank(treasury);
        vm.expectRevert(RoyaltyDistributor.NothingToClaim.selector);
        distributor.claimTo(address(0), payable(alice));
        assertEq(treasury.balance, 55 ether);
        assertEq(alice.balance, 0);
    }

    function test_claimForZeroHolderRejected() public {
        pay(55);
        vm.expectRevert(RoyaltyDistributor.InvalidReceiver.selector);
        distributor.claimFor(address(0), address(0));
    }

    function test_onlyCollectionMayUpdateSharesIncludingTreasuryAndDistributor() public {
        address[4] memory callers = [treasury, address(this), alice, address(distributor)];
        for (uint256 i; i < 4; ++i) {
            vm.prank(callers[i]);
            vm.expectRevert(RoyaltyDistributor.NotCollection.selector);
            distributor.updateShares(treasury, alice, 1);
        }
        assertEq(distributor.shares(treasury), 55);
        assertEq(distributor.shares(alice), 0);
    }

    function test_bindingCannotBeReopenedFromAConstructorInALaterTransaction() public {
        // A fresh contract whose constructor attempts to bind with the right arguments still fails:
        // the transient window closed in the deployment transaction and collection is already set.
        vm.expectRevert(RoyaltyDistributor.BindingClosed.selector);
        new SeedClock(treasury, address(distributor));
        assertEq(distributor.collection(), address(clock));
    }

    function test_syncTokenOnNonContractAssetReverts() public {
        vm.expectRevert();
        distributor.syncToken(alice);
        assertEq(distributor.receiptCount(alice), 0);
    }

    function test_syncTokenWithZeroBalanceRecordsNothing() public {
        MockIMD currency = new MockIMD();
        distributor.syncToken(address(currency));
        assertEq(distributor.receiptCount(address(currency)), 0);
        assertEq(distributor.totalReceived(address(currency)), 0);
    }

    function test_syncNativeWithNothingNewIsNoop() public {
        distributor.syncNative();
        assertEq(distributor.receiptCount(address(0)), 0);
        pay(55);
        distributor.syncNative();
        assertEq(distributor.receiptCount(address(0)), 1);
        assertEq(distributor.totalReceived(address(0)), 55);
    }

    function test_paginationBoundaryAtExactly64And65Receipts() public {
        for (uint256 i; i < 64; ++i) {
            pay(55);
        }
        assertEq(distributor.claimFor(address(0), treasury), 64 * 55);
        vm.expectRevert(RoyaltyDistributor.NothingToClaim.selector);
        distributor.claimFor(address(0), treasury);
        pay(55);
        assertEq(distributor.receiptCount(address(0)), 65);
        assertEq(distributor.claimFor(address(0), treasury), 55);
        assertEq(address(distributor).balance, 0);
    }

    function test_dustBelowTotalSharesGoesEntirelyToTokenOneHolder() public {
        mintAs(alice, 5);
        move(treasury, bob, 1);
        pay(59); // 60 shares, 59 wei: no receipt, all dust to the current holder of token 1.
        assertEq(distributor.receiptCount(address(0)), 0);
        assertEq(distributor.claimable(bob), 59);
        assertEq(distributor.claimable(alice), 0);
        assertEq(distributor.claimable(treasury), 0);
        pay(60);
        assertEq(distributor.claimable(alice), 5);
        assertEq(distributor.claimable(bob), 60);
        assertEq(distributor.claimable(treasury), 54);
    }

    function test_operatorTransferMovesFutureRoyaltiesOnly() public {
        mintAs(alice, 1);
        pay(56 ether);
        vm.prank(alice);
        clock.approve(operator, 56);
        validator.authorize(address(clock), operator, 56, true);
        vm.prank(operator);
        clock.safeTransferFrom(alice, carol, 56);
        pay(56 ether);
        assertEq(distributor.claimable(alice), 1 ether);
        assertEq(distributor.claimable(carol), 1 ether);
        assertEq(clock.getApproved(56), address(0));
    }

    // ---------------------------------------------------------------- checkpoint history

    /// forge-config: default.fuzz.runs = 200
    function testFuzz_sharesAtMatchesRecordedHistory(uint256 seed) public {
        address[3] memory people = [alice, bob, carol];
        mintAs(alice, 5);
        mintAs(bob, 5);
        uint64[] memory revisions = new uint64[](13);
        uint256[3][] memory balances = new uint256[3][](13);
        for (uint256 step; step < 13; ++step) {
            if (step != 0) {
                uint256 r = uint256(keccak256(abi.encode(seed, step)));
                uint256 id = 56 + r % 10;
                address from = clock.ownerOf(id);
                address to = people[(r >> 8) % 3];
                move(from, to, id);
            }
            revisions[step] = distributor.revision();
            for (uint256 p; p < 3; ++p) {
                balances[step][p] = clock.balanceOf(people[p]);
            }
        }
        for (uint256 step; step < 13; ++step) {
            for (uint256 p; p < 3; ++p) {
                assertEq(distributor.sharesAt(people[p], revisions[step]), balances[step][p]);
            }
        }
        assertEq(distributor.sharesAt(alice, 0), 0);
        assertEq(distributor.sharesAt(treasury, 1), 55);
    }

    /// forge-config: default.fuzz.runs = 300
    function testFuzz_singleReceiptSplitIsExactAndConserved(uint256 amount, uint8 aliceCount, uint8 bobCount)
        public
    {
        uint256 a = bound(aliceCount, 1, 5);
        uint256 b = bound(bobCount, 1, 5);
        amount = bound(amount, 0, 1e30);
        mintAs(alice, a);
        mintAs(bob, b);
        vm.deal(address(this), amount);
        pay(amount);
        uint256 supply = 55 + a + b;
        assertEq(distributor.claimable(alice), amount / supply * a);
        assertEq(distributor.claimable(bob), amount / supply * b);
        assertEq(distributor.claimable(treasury), amount / supply * 55 + amount % supply);
        assertEq(
            distributor.claimable(alice) + distributor.claimable(bob) + distributor.claimable(treasury),
            amount
        );
    }
}
