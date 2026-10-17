// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {SeedClockFixture} from "./helpers/Fixtures.sol";
import {SeedClock} from "../src/SeedClock.sol";
import {RoyaltyDistributor} from "../src/RoyaltyDistributor.sol";
import {DeploySeedClock, SeedClockDeploymentRehearsal} from "../script/DeploySeedClock.s.sol";

contract WindowProbe {
    function createDistributor(address treasury) external returns (RoyaltyDistributor) {
        return new RoyaltyDistributor(treasury);
    }
}

contract DeploymentTest is SeedClockFixture {
    function test_runtimeSizesAndForbiddenOpcodesMatchProtectedFloor() public view {
        assertLt(type(SeedClock).creationCode.length + 64, 49_152);
        assertLt(type(RoyaltyDistributor).creationCode.length + 32, 49_152);
        inspect(address(clock));
        inspect(address(distributor));
    }

    function test_noFactoryOrTreasuryOwnershipPrivileges() public view {
        (bool clockHasOwner,) = address(clock).staticcall(abi.encodeWithSignature("owner()"));
        (bool distributorHasOwner,) = address(distributor).staticcall(abi.encodeWithSignature("owner()"));
        assertFalse(clockHasOwner);
        assertFalse(distributorHasOwner);
        assertEq(clock.treasury(), treasury);
    }

    function test_badConstructorAddressesRevert() public {
        vm.expectRevert(RoyaltyDistributor.ZeroAddress.selector);
        new RoyaltyDistributor(address(0));
        vm.expectRevert(SeedClock.ZeroAddress.selector);
        new SeedClock(address(0), address(distributor));
        vm.expectRevert(SeedClock.ZeroAddress.selector);
        new SeedClock(treasury, address(0));
    }

    function test_bindingWindowExpiresAtTransactionBoundary() public {
        WindowProbe probe = new WindowProbe();
        RoyaltyDistributor orphan = probe.createDistributor(treasury);
        // Forge 1.8 treats each top-level external call here as a separate transaction, as does the
        // supplied deployment floor. A stale distributor can never be captured in a later transaction.
        vm.prank(alice);
        vm.expectRevert(RoyaltyDistributor.BindingClosed.selector);
        orphan.bindCollection(treasury, address(probe));
    }

    function test_unboundDistributorRejectsSyncAndDefersAllocation() public {
        WindowProbe probe = new WindowProbe();
        RoyaltyDistributor orphan = probe.createDistributor(treasury);
        (bool ok,) = address(orphan).call{value: 1 ether}("");
        assertTrue(ok);
        assertEq(orphan.totalReceived(address(0)), 0);
        vm.expectRevert(RoyaltyDistributor.NotBound.selector);
        orphan.syncNative();
        address asset = clock.IMD();
        vm.expectRevert(RoyaltyDistributor.NotBound.selector);
        orphan.syncToken(asset);
        assertEq(address(orphan).balance, 1 ether);
    }

    function test_counterfactualFundingIsClaimableAfterAtomicDeployment() public {
        SeedClockDeploymentRehearsal deployment = new SeedClockDeploymentRehearsal();
        bytes memory code = abi.encodePacked(type(RoyaltyDistributor).creationCode, abi.encode(treasury));
        address predicted = vm.computeCreate2Address(
            keccak256("SeedClock.distributor.rehearsal.v1"), keccak256(code), address(deployment)
        );
        vm.deal(predicted, 55 ether);
        (RoyaltyDistributor funded, SeedClock paired) =
            deployment.deploy(treasury, type(RoyaltyDistributor).creationCode, type(SeedClock).creationCode);
        assertEq(address(funded), predicted);
        assertEq(funded.collection(), address(paired));
        assertEq(funded.claimable(treasury), 55 ether);
        funded.claimFor(address(0), treasury);
        assertEq(treasury.balance, 55 ether);
    }

    function test_deployScriptUsesExplicitTreasuryAndAtomicPairing() public {
        DeploySeedClock script = new DeploySeedClock();
        (RoyaltyDistributor deployedDistributor, SeedClock deployedClock) = script.deploy(alice);
        assertEq(deployedClock.treasury(), alice);
        assertEq(deployedClock.balanceOf(alice), 55);
        assertEq(deployedDistributor.collection(), address(deployedClock));
        assertEq(deployedDistributor.treasury(), alice);
        assertEq(deployedClock.distributor(), address(deployedDistributor));
    }

    function inspect(address app) private view {
        bytes memory code = app.code;
        assertGt(code.length, 0);
        assertLe(code.length, 24_576);
        for (uint256 i; i < code.length; ++i) {
            uint8 op = uint8(code[i]);
            if (op >= 0x60 && op <= 0x7f) {
                i += op - 0x5f;
                continue;
            }
            assertTrue(op != 0xf2 && op != 0xf4 && op != 0xff);
        }
    }
}
