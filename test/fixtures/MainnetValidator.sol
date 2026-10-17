// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Vm} from "forge-std/Vm.sol";
import {MainnetValidatorCode} from "./MainnetValidatorCode.sol";

// Mainnet read-only snapshot. OpenSea StrictAuthorizedTransferSecurityRegistry.
// Source: https://etherscan.io/address/0xA000027A9B2802E1ddf7000061001e5c005A0000#code
// Block 26212558. Captured with eth_getCode / eth_createAccessList / eth_getStorageAt.
// Only nonzero global storage used by the exercised default policy is installed.
// No RPC is used by tests. This fixture is not a deployable project application.
library MainnetValidatorFixture {
    function install(Vm vm) internal {
        bytes memory initCode = vm.getCode("MainnetValidatorCode.sol:MainnetValidatorCode");
        address fixture;
        assembly ("memory-safe") { fixture := create(0, add(initCode, 32), mload(initCode)) }
        require(fixture != address(0), "fixture deployment");
        vm.etch(address(bytes20(hex"a000027a9b2802e1ddf7000061001e5c005a0000")), fixture.code);
        vm.store(
            address(bytes20(hex"a000027a9b2802e1ddf7000061001e5c005a0000")),
            0x08ad42b8c5cc6483fc6f741635eaa19fc52c5290bb801ae007ad7830329c2a0d,
            0x000000000000000000000000000056f7000000ece9003ca63978907a00ffd100
        );
        vm.store(
            address(bytes20(hex"a000027a9b2802e1ddf7000061001e5c005a0000")),
            0x121d4e837f0cb527a9e7076696e507aa39f8873813d427383ef90e76e36c3a60,
            0x0000000000000000000000009a1d00bed7cd04bcda516d721a596eb22aac6834
        );
        vm.store(
            address(bytes20(hex"a000027a9b2802e1ddf7000061001e5c005a0000")),
            0x121d4e837f0cb527a9e7076696e507aa39f8873813d427383ef90e76e36c3a61,
            0x0000000000000000000000009a1d001670c8b17f8b7900e8d7a41e785b3f0515
        );
        vm.store(
            address(bytes20(hex"a000027a9b2802e1ddf7000061001e5c005a0000")),
            0x729e8fd76847aff373d216f4a70fd90c2fca9a1c85c1439cb490880b9313796a,
            0x0000000000000000000000000000000000000000000000000000000000000001
        );
        vm.store(
            address(bytes20(hex"a000027a9b2802e1ddf7000061001e5c005a0000")),
            0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb4a,
            0x0000000000000000000000000000000000000000000000000000000000000001
        );
        vm.store(
            address(bytes20(hex"a000027a9b2802e1ddf7000061001e5c005a0000")),
            0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb4d,
            0x0000000000000000000000000000000000000000000000000000000000000002
        );
    }
}
