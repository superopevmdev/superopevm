// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title ICreate2
 * @dev Interface for CREATE2 operations
 */
interface ICreate2 {
    /**
     * @dev Deploys a contract using CREATE2
     * @param salt A salt to influence the contract address
     * @param bytecode The contract bytecode
     * @return The address of the deployed contract
     */
    function deploy(
        bytes32 salt,
        bytes calldata bytecode
    ) external returns (address);

    /**
     * @dev Computes the address of a contract deployed using CREATE2
     * @param salt A salt to influence the contract address
     * @param bytecodeHash The hash of the contract bytecode
     * @return The computed address
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash
    ) external view returns (address);
}
