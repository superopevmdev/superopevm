// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IUserOperation
 * @dev Interface for User Operation structure (ERC-4337)
 */
interface IUserOperation {
    struct UserOperation {
        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        uint256 callGasLimit;
        uint256 verificationGasLimit;
        uint256 preVerificationGas;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        bytes paymasterAndData;
        bytes signature;
    }
}
