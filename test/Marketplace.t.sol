// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {SeedClockFixture, MockIMD} from "./helpers/Fixtures.sol";
import {MainnetValidatorFixture} from "./fixtures/MainnetValidator.sol";

interface IStrictRegistry {
    function beforeAuthorizedTransfer(address token, uint256 tokenId) external;
    function afterAuthorizedTransfer(address token, uint256 tokenId) external;
    function getAuthorizerAccountsByCollection(address collection) external view returns (address[] memory);
}

/// @notice Exercises actual mainnet registry bytecode and default policy OFFLINE. The SignedZone
/// is impersonated at the authorization boundary; this is not a test of OpenSea API signatures.
contract MarketplaceTest is SeedClockFixture {
    address private constant SIGNED_ZONE = 0x000056F7000000EcE9003ca63978907a00FFD100;
    IStrictRegistry private registry;

    function setUp() public override {
        super.setUp();
        MainnetValidatorFixture.install(vm);
        registry = IStrictRegistry(clock.TRANSFER_VALIDATOR());
    }

    function test_mainnetRegistryRecognizesOpenSeaZoneAndAllowsOwnerGifts() public {
        assertEq(
            clock.TRANSFER_VALIDATOR().codehash,
            0xc7dfe8ae4da5613f6406eab346f0808ee2322316f44d186136c830a71491366c
        );
        address[] memory authorizers = registry.getAuthorizerAccountsByCollection(address(clock));
        assertEq(authorizers.length, 1);
        assertEq(authorizers[0], SIGNED_ZONE);
        mintAs(alice, 1);
        move(alice, bob, 56);
        assertEq(clock.ownerOf(56), bob);
    }

    function test_mainnetRegistryRejectsUnattestedApprovedOperator() public {
        mintAs(alice, 1);
        vm.prank(alice);
        clock.approve(operator, 56);
        vm.prank(operator);
        vm.expectRevert(bytes4(keccak256("StrictAuthorizedTransferSecurityRegistry__UnauthorizedTransfer()")));
        clock.transferFrom(alice, bob, 56);
    }

    function test_arbitraryCallerCannotImpersonateRoyaltyAuthorizer() public {
        vm.prank(operator);
        vm.expectRevert(
            bytes4(keccak256("StrictAuthorizedTransferSecurityRegistry__CallerIsNotValidAuthorizer()"))
        );
        registry.beforeAuthorizedTransfer(address(clock), 56);
    }

    function test_attestedTransferAndNativeRoyaltyFlow() public {
        mintAs(alice, 2);
        vm.prank(alice);
        clock.setApprovalForAll(operator, true);
        (address recipient, uint256 fee) = clock.royaltyInfo(56, 1 ether);
        assertEq(fee, 0.069 ether);
        assertEq(recipient, address(distributor));

        this.atomicAttestedTransfer(true);
        pay(fee); // Seaport's separate consideration item, after the NFT transfer in this example.

        uint256 perToken = fee / 57;
        assertEq(distributor.claimable(bob), perToken);
        assertEq(distributor.claimable(alice), perToken);
        assertEq(distributor.claimable(treasury), perToken * 55);
        assertEq(distributor.undistributed(address(0)), fee % 57); // Carried into the next receipt.
        distributor.claimFor(address(0), bob);
        assertEq(bob.balance, perToken);

        vm.prank(operator);
        vm.expectRevert(bytes4(keccak256("StrictAuthorizedTransferSecurityRegistry__UnauthorizedTransfer()")));
        clock.transferFrom(alice, bob, 57);
        vm.prank(bob);
        clock.approve(operator, 56);
        vm.prank(operator);
        vm.expectRevert(bytes4(keccak256("StrictAuthorizedTransferSecurityRegistry__UnauthorizedTransfer()")));
        clock.transferFrom(bob, alice, 56);
    }

    function test_attestedTransferAndERC20RoyaltyFlow() public {
        MockIMD paymentToken = new MockIMD();
        mintAs(alice, 1);
        vm.prank(alice);
        clock.approve(operator, 56);
        (, uint256 royalty) = clock.royaltyInfo(56, 10_000_000);
        assertEq(royalty, 690_000);
        this.atomicAttestedTransfer(false);
        paymentToken.mint(address(distributor), royalty);
        distributor.syncToken(address(paymentToken));
        distributor.claimFor(address(paymentToken), bob);
        distributor.claimFor(address(paymentToken), treasury);
        assertEq(paymentToken.balanceOf(bob), royalty / 56);
        assertEq(paymentToken.balanceOf(address(distributor)), royalty % 56); // Carried forward.
        assertEq(distributor.undistributed(address(paymentToken)), royalty % 56);
    }

    /// @dev Keep authorization, execution and clearing in ONE transaction, like Seaport. Forge 1.8
    /// makes separate top-level test calls separate transactions and clears transient authorizations.
    function atomicAttestedTransfer(bool safe) external {
        vm.prank(SIGNED_ZONE);
        registry.beforeAuthorizedTransfer(address(clock), 56);
        if (safe) {
            vm.prank(operator);
            vm.expectRevert(
                bytes4(keccak256("StrictAuthorizedTransferSecurityRegistry__UnauthorizedTransfer()"))
            );
            clock.transferFrom(alice, bob, 57);
        }
        vm.prank(operator);
        if (safe) clock.safeTransferFrom(alice, bob, 56);
        else clock.transferFrom(alice, bob, 56);
        vm.prank(SIGNED_ZONE);
        registry.afterAuthorizedTransfer(address(clock), 56);
        vm.prank(bob);
        clock.approve(operator, 56);
        vm.prank(operator);
        vm.expectRevert(bytes4(keccak256("StrictAuthorizedTransferSecurityRegistry__UnauthorizedTransfer()")));
        clock.transferFrom(bob, alice, 56);
    }
}
