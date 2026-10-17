// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {SeedClockFixture, CallbackWallet, MockTransferValidator} from "./helpers/Fixtures.sol";
import {SeedClock} from "../src/SeedClock.sol";
import {RoyaltyDistributor} from "../src/RoyaltyDistributor.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {ICreatorToken, ITransferValidator} from "../src/interfaces/ICreatorToken.sol";

contract SeedClockTest is SeedClockFixture {
    function test_deploymentMintsExactly55AndHasNoAdministrativeMint() public view {
        assertEq(clock.name(), "SeedClock");
        assertEq(clock.symbol(), "SCLOCK");
        assertEq(clock.totalSupply(), 55);
        assertEq(clock.balanceOf(treasury), 55);
        assertEq(distributor.totalShares(), 55);
        assertEq(distributor.shares(treasury), 55);
        assertEq(distributor.collection(), address(clock));
        assertEq(distributor.treasury(), treasury);
        assertEq(clock.publicMinted(treasury), 0);
        for (uint256 id = 1; id <= 55; ++id) {
            assertEq(clock.ownerOf(id), treasury);
        }
    }

    function test_interfacesAndFixedRoyaltyConfiguration() public view {
        assertTrue(clock.supportsInterface(type(IERC165).interfaceId));
        assertTrue(clock.supportsInterface(type(IERC721).interfaceId));
        assertTrue(clock.supportsInterface(type(IERC721Metadata).interfaceId));
        assertTrue(clock.supportsInterface(type(IERC2981).interfaceId));
        assertTrue(clock.supportsInterface(type(ICreatorToken).interfaceId));
        assertFalse(clock.supportsInterface(0xffffffff));
        (address recipient, address distribution, uint96 bps) = clock.royaltyConfiguration();
        assertEq(recipient, address(distributor));
        assertEq(distribution, recipient);
        assertEq(bps, 690);
        assertEq(clock.royaltyRecipient(), recipient);
        assertEq(clock.getTransferValidator(), clock.TRANSFER_VALIDATOR());
        (bytes4 selector, bool isView) = clock.getTransferValidationFunction();
        assertEq(selector, ITransferValidator.validateTransfer.selector);
        assertTrue(isView);
    }

    function test_mintRequiresOneWholeIMDAndRechecksEveryTime() public {
        vm.startPrank(alice);
        vm.expectRevert(SeedClock.IMDRequired.selector);
        clock.mint(1);
        vm.stopPrank();
        imd.mint(alice, 1 ether - 1);
        vm.prank(alice);
        vm.expectRevert(SeedClock.IMDRequired.selector);
        clock.mint(1);
        imd.mint(alice, 1);
        vm.prank(alice);
        clock.mint(2);
        assertEq(clock.ownerOf(56), alice);
        assertEq(clock.publicMinted(alice), 2);
        assertEq(distributor.shares(alice), 2);
        imd.destroy(alice, 1);
        vm.prank(alice);
        vm.expectRevert(SeedClock.IMDRequired.selector);
        clock.mint(1);
        assertEq(clock.totalSupply(), 57);
    }

    function test_missingIMDContractFailsClosed() public {
        vm.etch(clock.IMD(), "");
        vm.prank(alice);
        vm.expectRevert(SeedClock.IMDUnavailable.selector);
        clock.mint(1);
    }

    function test_rejectsZeroOverlargeAndPaidMints() public {
        eligible(alice);
        vm.startPrank(alice);
        vm.expectRevert(SeedClock.InvalidQuantity.selector);
        clock.mint(0);
        vm.expectRevert(SeedClock.InvalidQuantity.selector);
        clock.mint(6);
        vm.deal(alice, 1 ether);
        (bool ok,) = address(clock).call{value: 1}(abi.encodeCall(clock.mint, (1)));
        assertFalse(ok);
        vm.stopPrank();
        assertEq(clock.totalSupply(), 55);
    }

    function test_lifetimeWalletLimitDoesNotResetAfterTransfer() public {
        mintAs(alice, 3);
        move(alice, bob, 56);
        vm.prank(alice);
        clock.mint(2);
        vm.prank(alice);
        vm.expectRevert(SeedClock.WalletLimit.selector);
        clock.mint(1);
        // Receiving tokens does not consume the recipient's public mint allowance.
        mintAs(bob, 5);
        assertEq(clock.balanceOf(bob), 6);
        assertEq(clock.publicMinted(alice), 5);
    }

    function test_all5500PublicTokensAndHardCap() public {
        for (uint256 i; i < 1100; ++i) {
            address wallet = address(uint160(0x100000 + i));
            mintAs(wallet, 5);
        }
        assertEq(clock.totalSupply(), 5555);
        assertEq(distributor.totalShares(), 5555);
        assertEq(clock.ownerOf(5555), address(uint160(0x100000 + 1099)));
        eligible(alice);
        vm.prank(alice);
        vm.expectRevert(SeedClock.SoldOut.selector);
        clock.mint(1);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, 5556));
        clock.ownerOf(5556);
    }

    function test_receiverRejectionRollsBackAllMintAccounting() public {
        CallbackWallet wallet = new CallbackWallet(clock, distributor);
        eligible(address(wallet));
        wallet.configure(true, false, false, false);
        vm.expectRevert("reject NFT");
        wallet.mint(5);
        assertEq(clock.totalSupply(), 55);
        assertEq(clock.publicMinted(address(wallet)), 0);
        assertEq(distributor.totalShares(), 55);
        assertEq(distributor.shares(address(wallet)), 0);
    }

    function test_receiverCannotReenterMintAndSeesConsistentShares() public {
        CallbackWallet wallet = new CallbackWallet(clock, distributor);
        eligible(address(wallet));
        wallet.configure(false, false, true, false);
        wallet.mint(5);
        assertTrue(wallet.attempted());
        assertFalse(wallet.reentered());
        assertEq(clock.balanceOf(address(wallet)), 5);
        assertEq(clock.totalSupply(), 60);
    }

    function test_operatorTransferRequiresValidatorAuthorization() public {
        mintAs(alice, 2);
        vm.prank(alice);
        clock.setApprovalForAll(operator, true);
        vm.prank(operator);
        vm.expectRevert(MockTransferValidator.UnauthorizedTransfer.selector);
        clock.transferFrom(alice, bob, 56);
        validator.authorize(address(clock), operator, 56, true);
        vm.prank(operator);
        clock.transferFrom(alice, bob, 56);
        assertEq(clock.ownerOf(56), bob);
        assertEq(distributor.shares(alice), 1);
        assertEq(distributor.shares(bob), 1);
        // Authorization is token-specific, and applies to both safeTransferFrom overloads.
        vm.prank(operator);
        vm.expectRevert(MockTransferValidator.UnauthorizedTransfer.selector);
        clock.safeTransferFrom(alice, bob, 57);
        vm.prank(operator);
        vm.expectRevert(MockTransferValidator.UnauthorizedTransfer.selector);
        clock.safeTransferFrom(alice, bob, 57, "");
    }

    function test_selfTransfersAndDirectGiftsCannotChangeMintHistoryOrCreateShares() public {
        mintAs(alice, 1);
        move(alice, alice, 56);
        assertEq(distributor.shares(alice), 1);
        move(alice, bob, 56);
        assertEq(distributor.shares(alice), 0);
        assertEq(distributor.shares(bob), 1);
        assertEq(clock.publicMinted(alice), 1);
        assertEq(distributor.totalShares(), 56);
    }

    function test_transfersToDistributorOrCollectionRejectedSoNoShareIsStranded() public {
        mintAs(alice, 2);
        address[2] memory sinks = [address(distributor), address(clock)];
        for (uint256 i; i < 2; ++i) {
            vm.startPrank(alice);
            vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, sinks[i]));
            clock.transferFrom(alice, sinks[i], 56);
            vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, sinks[i]));
            clock.safeTransferFrom(alice, sinks[i], 57);
            vm.stopPrank();
            assertEq(distributor.shares(sinks[i]), 0);
        }
        assertEq(clock.ownerOf(56), alice);
        assertEq(distributor.shares(alice), 2);
    }

    function test_unapprovedTransfersRejectedEvenWithValidatorPermission() public {
        mintAs(alice, 1);
        validator.authorize(address(clock), operator, 56, true);
        vm.prank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(IERC721Errors.ERC721InsufficientApproval.selector, operator, 56)
        );
        clock.transferFrom(alice, bob, 56);
    }

    function test_missingValidatorFailsClosedButDoesNotPauseMint() public {
        vm.etch(clock.TRANSFER_VALIDATOR(), "");
        mintAs(alice, 1);
        vm.prank(alice);
        vm.expectRevert(SeedClock.ValidatorUnavailable.selector);
        clock.transferFrom(alice, bob, 56);
        assertEq(clock.ownerOf(56), alice);
    }

    function test_noCallerCanDisableRoyaltiesOrMintAsAdmin() public {
        vm.startPrank(treasury);
        vm.expectRevert(SeedClock.RoyaltiesArePermanent.selector);
        clock.setTransferValidator(address(0));
        (bool ok,) = address(clock).call(abi.encodeWithSignature("ownerMint(address,uint256)", treasury, 1));
        assertFalse(ok);
        (ok,) = address(clock).call(abi.encodeWithSignature("pause()"));
        assertFalse(ok);
        (ok,) = address(clock).call(abi.encodeWithSignature("setTreasury(address)", alice));
        assertFalse(ok);
        vm.stopPrank();
    }

    function testFuzz_royaltyIs690BpsWithoutOverflow(uint256 price) public view {
        (address receiver, uint256 amount) = clock.royaltyInfo(1, price);
        assertEq(receiver, address(distributor));
        assertEq(amount, (price / 10_000) * 690 + (price % 10_000) * 690 / 10_000);
        assertLe(amount, price);
    }

    function testFuzz_mintEligibility(uint96 balance, uint8 quantity) public {
        uint256 n = bound(quantity, 1, 5);
        imd.mint(alice, balance);
        vm.prank(alice);
        if (balance < 1 ether) vm.expectRevert(SeedClock.IMDRequired.selector);
        clock.mint(n);
        assertEq(clock.totalSupply(), balance < 1 ether ? 55 : 55 + n);
    }
}
