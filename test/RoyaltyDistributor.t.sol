// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {SeedClockFixture, CallbackWallet, MockIMD} from "./helpers/Fixtures.sol";
import {RoyaltyDistributor} from "../src/RoyaltyDistributor.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FalseReturnToken is MockIMD {
    function transfer(address, uint256) public pure override returns (bool) {
        return false;
    }
}

contract DonateBack {
    RoyaltyDistributor private immutable distributor;
    bool private donated;

    constructor(RoyaltyDistributor distributor_) {
        distributor = distributor_;
    }

    receive() external payable {
        if (!donated) {
            donated = true;
            (bool ok,) = address(distributor).call{value: 55}("");
            require(ok);
        }
    }
}

contract RoyaltyDistributorTest is SeedClockFixture {
    function test_receiptProportionalToAllCurrentBalances() public {
        mintAs(alice, 3);
        mintAs(bob, 2);
        pay(60 ether);
        assertEq(distributor.claimable(treasury), 55 ether);
        assertEq(distributor.claimable(alice), 3 ether);
        assertEq(distributor.claimable(bob), 2 ether);
        vm.prank(alice);
        assertEq(distributor.claim(), 3 ether);
        assertEq(alice.balance, 3 ether);
        distributor.claimFor(address(0), bob);
        distributor.claimFor(address(0), treasury);
        assertEq(address(distributor).balance, 0);
        assertEq(distributor.totalReceived(address(0)), 60 ether);
        assertEq(distributor.totalClaimed(address(0)), 60 ether);
    }

    function test_newMintsCannotClaimEarlierRoyalties() public {
        pay(55 ether);
        mintAs(alice, 5);
        assertEq(distributor.claimable(alice), 0);
        pay(60 ether);
        assertEq(distributor.claimable(alice), 5 ether);
        assertEq(distributor.claimable(treasury), 110 ether);
    }

    function test_transferPreservesEarnedRoyaltiesAndChangesFutureEntitlement() public {
        mintAs(alice, 1);
        pay(56 ether);
        uint64 beforeTransfer = distributor.revision();
        move(alice, bob, 56);
        pay(112 ether);
        assertEq(distributor.sharesAt(alice, beforeTransfer), 1);
        assertEq(distributor.sharesAt(bob, beforeTransfer), 0);
        assertEq(distributor.sharesAt(alice, distributor.revision()), 0);
        assertEq(distributor.claimable(alice), 1 ether);
        assertEq(distributor.claimable(bob), 2 ether);
        distributor.claimFor(address(0), alice);
        move(bob, alice, 56);
        distributor.claimFor(address(0), bob);
        vm.prank(alice);
        vm.expectRevert(RoyaltyDistributor.NothingToClaim.selector);
        distributor.claim();
        assertEq(alice.balance, 1 ether);
        assertEq(bob.balance, 2 ether);
    }

    function test_tokenCyclingAndSelfTransferCannotDoubleClaim() public {
        mintAs(alice, 1);
        pay(56 ether);
        distributor.claimFor(address(0), alice);
        for (uint256 i; i < 4; ++i) {
            move(alice, bob, 56);
            move(bob, alice, 56);
        }
        move(alice, alice, 56);
        assertEq(distributor.claimable(alice), 0);
        assertEq(distributor.claimable(bob), 0);
        assertEq(distributor.totalClaimed(address(0)), 1 ether);
    }

    function test_remainderCarriesIntoNextReceiptInsteadOfOneHolder() public {
        pay(1);
        move(treasury, alice, 1); // Holding token 1 earns no remainder.
        pay(56); // Pool 57 over 55 shares: one per share, two carried.
        assertEq(distributor.claimable(treasury), 54);
        assertEq(distributor.claimable(alice), 1);
        assertEq(distributor.undistributed(address(0)), 2);
        pay(53); // Pool 55: one per share, nothing carried.
        assertEq(distributor.undistributed(address(0)), 0);
        distributor.claimFor(address(0), treasury);
        distributor.claimFor(address(0), alice);
        assertEq(treasury.balance, 108);
        assertEq(alice.balance, 2);
        assertEq(address(distributor).balance, 0);
        assertEq(distributor.totalClaimed(address(0)), 110);
    }

    function test_lowDecimalRemainderIsNotRedirectedToTokenOneHolder() public {
        MockIMD currency = new MockIMD();
        mintAs(alice, 5); // 60 shares; the treasury holds token 1.
        currency.mint(address(distributor), 10_000);
        distributor.syncToken(address(currency));
        (uint256 treasuryAmount,) = distributor.claimable(address(currency), treasury);
        (uint256 aliceAmount,) = distributor.claimable(address(currency), alice);
        assertEq(treasuryAmount, 166 * 55);
        assertEq(aliceAmount, 166 * 5);
        assertEq(distributor.undistributed(address(currency)), 40);
    }

    function test_tinyAndZeroReceiptsDoNotGrowQueue() public {
        pay(0);
        for (uint256 i; i < 54; ++i) {
            pay(1);
        }
        assertEq(distributor.receiptCount(address(0)), 0);
        assertEq(distributor.undistributed(address(0)), 54);
        assertEq(distributor.claimable(treasury), 0);
        pay(1); // The carry reaches one wei per share and becomes a receipt.
        assertEq(distributor.receiptCount(address(0)), 1);
        assertEq(distributor.claimable(treasury), 55);
        distributor.claimFor(address(0), treasury);
        assertEq(address(distributor).balance, 0);
    }

    function test_subShareAmountEmitsNoReceiptIndex() public {
        vm.expectEmit(address(distributor));
        emit RoyaltyDistributor.RoyaltyReceived(address(0), 1, distributor.NO_RECEIPT(), 1);
        pay(1);
        vm.expectEmit(address(distributor));
        emit RoyaltyDistributor.RoyaltyReceived(address(0), 55, 0, 1);
        pay(55);
        vm.expectEmit(address(distributor));
        emit RoyaltyDistributor.RoyaltyReceived(address(0), 110, 1, 1);
        pay(110);
        (uint64 atRevision, uint256 perToken, uint256 cumulative) = distributor.receipt(address(0), 1);
        assertEq(atRevision, 1);
        assertEq(perToken, 2);
        assertEq(cumulative, 3);
    }

    function test_claimPaginatesOverBalanceSegments() public {
        mintAs(alice, 1);
        for (uint256 i; i < 70; ++i) {
            pay(56); // Alice holds token 56.
            move(alice, bob, 56);
            pay(56); // Bob holds token 56.
            move(bob, alice, 56);
        }
        assertEq(distributor.receiptCount(address(0)), 140);
        (uint256 first, uint256 end) = distributor.claimable(address(0), alice);
        assertEq(first, 32);
        assertEq(end, 64);
        assertEq(distributor.claimFor(address(0), alice), 32);
        assertEq(distributor.nextReceipt(address(0), alice), 64);
        assertEq(distributor.claimFor(address(0), alice), 32);
        assertEq(distributor.nextReceipt(address(0), alice), 128);
        assertEq(distributor.claimFor(address(0), alice), 6);
        assertEq(distributor.nextReceipt(address(0), alice), 140);
        vm.expectRevert(RoyaltyDistributor.NothingToClaim.selector);
        distributor.claimFor(address(0), alice);
        // The treasury's balance never changed: one segment, one claim.
        assertEq(distributor.claimFor(address(0), treasury), 140 * 55);
        assertEq(distributor.nextReceipt(address(0), treasury), 140);
    }

    function test_lateHolderSkipsEarlierReceiptsInOneCheapClaim() public {
        for (uint256 i; i < 1000; ++i) {
            pay(55); // Includes the spam pattern: the smallest amount that creates a receipt.
        }
        mintAs(alice, 5);
        pay(60 ether);
        uint256 gasBefore = gasleft();
        assertEq(distributor.claimFor(address(0), alice), 5 ether);
        assertLt(gasBefore - gasleft(), 200_000); // Was about 7k gas per receipt before.
        assertEq(distributor.nextReceipt(address(0), alice), 1001);
        // A long-standing holder settles all 1001 receipts in one claim too.
        gasBefore = gasleft();
        assertEq(distributor.claimFor(address(0), treasury), 1000 * 55 + 55 ether);
        assertLt(gasBefore - gasleft(), 200_000);
    }

    function test_holderReturningAfterSellingSkipsGapInOneClaim() public {
        mintAs(alice, 1);
        pay(56);
        move(alice, bob, 56);
        for (uint256 i; i < 500; ++i) {
            pay(56);
        }
        move(bob, alice, 56);
        pay(56);
        assertEq(distributor.claimFor(address(0), alice), 2);
        assertEq(distributor.nextReceipt(address(0), alice), 502);
        assertEq(distributor.claimFor(address(0), bob), 500);
    }

    function test_wethReceivedBeforeShareChangeBelongsToHoldersOfRecord() public {
        vm.etch(distributor.WETH(), address(new MockIMD()).code);
        MockIMD weth = MockIMD(distributor.WETH());
        weth.mint(address(distributor), 55 ether);
        mintAs(alice, 5); // The first share change records the earlier WETH first.
        assertEq(distributor.receiptCount(address(weth)), 1);
        distributor.syncToken(address(weth)); // Idempotent.
        assertEq(distributor.receiptCount(address(weth)), 1);
        (uint256 aliceAmount,) = distributor.claimable(address(weth), alice);
        (uint256 treasuryAmount,) = distributor.claimable(address(weth), treasury);
        assertEq(aliceAmount, 0);
        assertEq(treasuryAmount, 55 ether);
        weth.mint(address(distributor), 60 ether);
        move(treasury, bob, 1);
        (aliceAmount,) = distributor.claimable(address(weth), alice);
        assertEq(aliceAmount, 5 ether);
        assertEq(distributor.claimFor(address(weth), treasury), 110 ether);
        assertEq(distributor.claimFor(address(weth), alice), 5 ether);
        assertEq(weth.balanceOf(address(distributor)), 0);
    }

    function test_anyCallerCanAssistButCannotRedirectAnotherHoldersClaim() public {
        pay(55 ether);
        vm.prank(alice);
        distributor.claimFor(address(0), treasury);
        assertEq(treasury.balance, 55 ether);
        assertEq(alice.balance, 0);
        vm.prank(alice);
        assertEq(distributor.claimTo(address(0), payable(alice)), 0); // Advances Alice's empty snapshot.
        assertEq(alice.balance, 0);
    }

    function test_claimReentrancyCannotDrainOtherHolders() public {
        CallbackWallet wallet = new CallbackWallet(clock, distributor);
        eligible(address(wallet));
        wallet.configure(false, false, false, true);
        wallet.mint(5);
        pay(60 ether);
        wallet.claim();
        assertTrue(wallet.attempted());
        assertFalse(wallet.reentered());
        assertEq(address(wallet).balance, 5 ether);
        assertEq(address(distributor).balance, 55 ether);
        assertEq(distributor.claimable(address(wallet)), 0);
    }

    function test_rejectingReceiverCannotBlockOthersAndCanChooseClaimDestination() public {
        CallbackWallet wallet = new CallbackWallet(clock, distributor);
        eligible(address(wallet));
        wallet.mint(1);
        wallet.configure(false, true, false, false);
        pay(56 ether);
        vm.expectRevert(RoyaltyDistributor.PaymentFailed.selector);
        wallet.claim();
        assertEq(distributor.claimable(address(wallet)), 1 ether);
        assertEq(distributor.nextReceipt(address(0), address(wallet)), 0);
        distributor.claimFor(address(0), treasury);
        assertEq(treasury.balance, 55 ether);
        wallet.claimTo(payable(alice));
        assertEq(alice.balance, 1 ether);
        assertEq(address(distributor).balance, 0);
    }

    function test_receiptDuringClaimCallbackIsAccountedAndNotOverwritten() public {
        DonateBack receiver = new DonateBack(distributor);
        pay(55 ether);
        vm.prank(treasury);
        distributor.claimTo(address(0), payable(address(receiver)));
        assertEq(distributor.totalReceived(address(0)), 55 ether + 55);
        assertEq(distributor.totalClaimed(address(0)), 55 ether);
        assertEq(distributor.claimable(treasury), 55);
        distributor.claimFor(address(0), treasury);
        assertEq(address(distributor).balance, 0);
    }

    function test_forcedETHCanBeSyncedByAnyone() public {
        vm.deal(address(distributor), 55 ether);
        assertEq(distributor.claimable(treasury), 0);
        vm.prank(bob);
        distributor.syncNative();
        assertEq(distributor.claimable(treasury), 55 ether);
        distributor.syncNative();
        assertEq(distributor.receiptCount(address(0)), 1);
    }

    function test_erc20RoyaltiesSnapshotOnPermissionlessSyncAndCannotBeCountedTwice() public {
        MockIMD currency = new MockIMD();
        mintAs(alice, 5);
        currency.mint(address(distributor), 6000);
        (uint256 pending,) = distributor.claimable(address(currency), alice);
        assertEq(pending, 0);
        vm.prank(bob);
        distributor.syncToken(address(currency));
        (pending,) = distributor.claimable(address(currency), alice);
        assertEq(pending, 500);
        distributor.syncToken(address(currency));
        assertEq(distributor.receiptCount(address(currency)), 1);
        distributor.claimFor(address(currency), alice);
        distributor.claimFor(address(currency), treasury);
        assertEq(currency.balanceOf(alice), 500);
        assertEq(currency.balanceOf(treasury), 5500);
        assertEq(currency.balanceOf(address(distributor)), 0);
        currency.mint(address(distributor), 600);
        distributor.syncToken(address(currency));
        distributor.claimFor(address(currency), alice);
        assertEq(currency.balanceOf(alice), 550);
        assertEq(distributor.totalReceived(address(currency)), 6600);
    }

    function test_erc20OwnershipChangesBeforeSyncUseSyncTimeBalances() public {
        MockIMD currency = new MockIMD();
        mintAs(alice, 1);
        currency.mint(address(distributor), 56);
        move(alice, bob, 56);
        distributor.syncToken(address(currency));
        (uint256 beforeHolder,) = distributor.claimable(address(currency), alice);
        (uint256 currentHolder,) = distributor.claimable(address(currency), bob);
        assertEq(beforeHolder, 0);
        assertEq(currentHolder, 1);
    }

    function test_falseReturningERC20RollsBackClaimAndCannotAffectETH() public {
        FalseReturnToken currency = new FalseReturnToken();
        currency.mint(address(distributor), 55);
        distributor.syncToken(address(currency));
        vm.expectRevert(
            abi.encodeWithSelector(SafeERC20.SafeERC20FailedOperation.selector, address(currency))
        );
        distributor.claimFor(address(currency), treasury);
        assertEq(distributor.nextReceipt(address(currency), treasury), 0);
        assertEq(distributor.accountedBalance(address(currency)), 55);
        pay(55 ether);
        distributor.claimFor(address(0), treasury);
        assertEq(treasury.balance, 55 ether);
    }

    function test_negativeRebaseRejectedAndCannotBlockOtherAssets() public {
        MockIMD currency = new MockIMD();
        currency.mint(address(distributor), 55);
        distributor.syncToken(address(currency));
        currency.destroy(address(distributor), 1);
        vm.expectRevert(RoyaltyDistributor.UnsupportedBalanceDecrease.selector);
        distributor.syncToken(address(currency));
        pay(55);
        assertEq(distributor.claimFor(address(0), treasury), 55);
    }

    function test_invalidDestinationsAndNativeTokenSyncRejected() public {
        pay(55);
        vm.startPrank(treasury);
        vm.expectRevert(RoyaltyDistributor.InvalidReceiver.selector);
        distributor.claimTo(address(0), payable(address(0)));
        vm.expectRevert(RoyaltyDistributor.InvalidReceiver.selector);
        distributor.claimTo(address(0), payable(address(distributor)));
        vm.expectRevert(RoyaltyDistributor.NativeAsset.selector);
        distributor.syncToken(address(0));
        vm.stopPrank();
    }

    function test_unauthorizedLedgerMutationRebindingAndSweepFail() public {
        vm.startPrank(treasury);
        vm.expectRevert(RoyaltyDistributor.NotCollection.selector);
        distributor.updateShares(address(0), treasury, 5556);
        vm.expectRevert(RoyaltyDistributor.BindingClosed.selector);
        distributor.bindCollection(treasury, treasury);
        (bool ok,) = address(distributor).call(abi.encodeWithSignature("withdraw(address)", treasury));
        assertFalse(ok);
        vm.stopPrank();
    }

    function testFuzz_conservationIncludingDustAndTransfers(uint96 first, uint96 second, uint8 quantity)
        public
    {
        uint256 n = bound(quantity, 1, 5);
        uint256 one = bound(first, 0, 1000 ether);
        uint256 two = bound(second, 0, 1000 ether);
        mintAs(alice, n);
        pay(one);
        move(alice, bob, 56);
        move(treasury, bob, 1);
        pay(two);
        uint256 carry = distributor.undistributed(address(0));
        assertLt(carry, 55 + n);
        uint256 total =
            distributor.claimable(treasury) + distributor.claimable(alice) + distributor.claimable(bob);
        assertEq(total + carry, one + two);
        if (distributor.claimable(treasury) != 0) distributor.claimFor(address(0), treasury);
        if (distributor.claimable(alice) != 0) distributor.claimFor(address(0), alice);
        if (distributor.claimable(bob) != 0) distributor.claimFor(address(0), bob);
        assertEq(address(distributor).balance, carry);
        assertEq(distributor.accountedBalance(address(0)), carry);
        assertEq(distributor.totalClaimed(address(0)), one + two - carry);
    }
}
