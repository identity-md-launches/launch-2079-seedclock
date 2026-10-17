// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IRoyaltyDistributor {
    function bindCollection(address treasury, address deploymentCaller) external;
    function updateShares(address from, address to, uint256 tokenId) external;
}
