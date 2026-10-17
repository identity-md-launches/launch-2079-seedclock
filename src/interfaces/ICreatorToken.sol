// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @notice Limit Break's ERC721-C discovery interface, also used by OpenSea.
interface ICreatorToken {
    event TransferValidatorUpdated(address oldValidator, address newValidator);

    function getTransferValidator() external view returns (address validator);
    function getTransferValidationFunction() external view returns (bytes4 selector, bool isView);
    function setTransferValidator(address validator) external;
}

interface ITransferValidator {
    function validateTransfer(address caller, address from, address to, uint256 tokenId) external view;
}
