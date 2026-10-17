// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {RoyaltyDistributor} from "../src/RoyaltyDistributor.sol";
import {SeedClock} from "../src/SeedClock.sol";

/// @notice Local rehearsal of the launch factory's atomic, ordered CREATE2 deployment.
/// This helper is NOT a launch application. Never deploy the two applications in separate transactions.
contract SeedClockDeploymentRehearsal {
    error DeploymentFailed();

    function deploy(address treasury, bytes memory distributorCode, bytes memory collectionCode)
        external
        returns (RoyaltyDistributor distributor, SeedClock collection)
    {
        bytes memory code = abi.encodePacked(distributorCode, abi.encode(treasury));
        address deployed;
        bytes32 salt = keccak256("SeedClock.distributor.rehearsal.v1");
        assembly ("memory-safe") {
            deployed := create2(0, add(code, 32), mload(code), salt)
        }
        if (deployed == address(0)) revert DeploymentFailed();
        distributor = RoyaltyDistributor(payable(deployed));
        code = abi.encodePacked(collectionCode, abi.encode(treasury, deployed));
        salt = keccak256("SeedClock.collection.rehearsal.v1");
        assembly ("memory-safe") {
            deployed := create2(0, add(code, 32), mload(code), salt)
        }
        if (deployed == address(0)) revert DeploymentFailed();
        collection = SeedClock(deployed);
    }
}

/// @notice Dry run only; no environment, keys, network, broadcast, or post-deployment settings.
/// Production uses IdentityMD's attested factory launch and its own salts, not this helper's addresses.
contract DeploySeedClock is Script {
    address public constant LAUNCH_TREASURY = address(bytes20(hex"3d6a89c8751a45dd577a4c1f3b34e71c58236193"));

    function run() external returns (RoyaltyDistributor distributor, SeedClock collection) {
        return deploy(LAUNCH_TREASURY);
    }

    function deploy(address treasury) public returns (RoyaltyDistributor distributor, SeedClock collection) {
        SeedClockDeploymentRehearsal rehearsal = new SeedClockDeploymentRehearsal();
        return rehearsal.deploy(
            treasury,
            vm.getCode("RoyaltyDistributor.sol:RoyaltyDistributor"),
            vm.getCode("SeedClock.sol:SeedClock")
        );
    }
}
