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

    function test_allRoundingDustClaimableByTokenOneHolderAtReceipt() public {
        pay(1);
        move(treasury, alice, 1);
        pay(56); // 55 indivisible shares, one wei remainder belongs to Alice.
        assertEq(distributor.claimable(treasury), 55);
        assertEq(distributor.claimable(alice), 2);
        distributor.claimFor(address(0), treasury);
        distributor.claimFor(address(0), alice);
        assertEq(address(distributor).balance, 0);
        assertEq(distributor.totalClaimed(address(0)), 57);
    }

    function test_tinyAndZeroReceiptsDoNotGrowQueue() public {
        pay(0);
        for (uint256 i; i < 100; ++i) {
            pay(1);
        }
        assertEq(distributor.receiptCount(address(0)), 0);
        assertEq(distributor.claimable(treasury), 100);
        distributor.claimFor(address(0), treasury);
        assertEq(address(distributor).balance, 0);
    }

    function test_claimPaginationProgressesWithoutUnboundedLoops() public {
        for (uint256 i; i < 130; ++i) {
            pay(55);
        }
        assertEq(distributor.receiptCount(address(0)), 130);
        assertEq(distributor.claimable(treasury), 64 * 55);
        distributor.claimFor(address(0), treasury);
        assertEq(distributor.nextReceipt(address(0), treasury), 64);
        distributor.claimFor(address(0), treasury);
        assertEq(distributor.nextReceipt(address(0), treasury), 128);
        distributor.claimFor(address(0), treasury);
        assertEq(distributor.nextReceipt(address(0), treasury), 130);
        assertEq(treasury.balance, 130 * 55);
        assertEq(address(distributor).balance, 0);
    }

    function test_zeroEntitlementBatchCanAdvanceToLaterEarnedReceipts() public {
        for (uint256 i; i < 65; ++i) {
            pay(55);
        }
        mintAs(alice, 1);
        pay(56);
        assertEq(distributor.claimFor(address(0), alice), 0);
        assertEq(distributor.nextReceipt(address(0), alice), 64);
        assertEq(distributor.claimFor(address(0), alice), 1);
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
        uint256 total =
            distributor.claimable(treasury) + distributor.claimable(alice) + distributor.claimable(bob);
        assertEq(total, one + two);
        if (distributor.claimable(treasury) != 0) distributor.claimFor(address(0), treasury);
        if (distributor.claimable(alice) != 0) distributor.claimFor(address(0), alice);
        if (distributor.claimable(bob) != 0) distributor.claimFor(address(0), bob);
        assertEq(address(distributor).balance, 0);
        assertEq(distributor.totalClaimed(address(0)), one + two);
    }
}
