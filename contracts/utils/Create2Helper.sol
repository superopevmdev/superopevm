// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Create2 as Create2} from "@superopevm/contracts/utils/Create2.sol";
import {Strings as Strings} from "@superopevm/contracts/utils/Strings.sol";

/**
 * @title Create2Helper
 * @dev Additional utilities for CREATE2 operations
 */
library Create2Helper {
    /**
     * @dev Computes the address of a contract with constructor arguments
     * @param deployer The address that will deploy the contract
     * @param salt A salt to influence the contract address
     * @param bytecode The contract bytecode
     * @param args The constructor arguments
     * @return The computed address
     */
    function computeAddressWithArgs(
        address deployer,
        bytes32 salt,
        bytes memory bytecode,
        bytes memory args
    ) internal pure returns (address) {
        bytes memory bytecodeWithArgs = abi.encodePacked(bytecode, args);
        bytes32 bytecodeHash = keccak256(bytecodeWithArgs);
        return Create2.computeAddress(deployer, salt, bytecodeHash);
    }

    /**
     * @dev Generates a salt from a string
     * @param source The string to generate salt from
     * @return The generated salt
     */
    function generateSalt(string memory source) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(source));
    }

    /**
     * @dev Generates a salt from an address
     * @param source The address to generate salt from
     * @return The generated salt
     */
    function generateSalt(address source) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(source)));
    }

    /**
     * @dev Generates a salt from a uint256
     * @param source The uint256 to generate salt from
     * @return The generated salt
     */
    function generateSalt(uint256 source) internal pure returns (bytes32) {
        return bytes32(source);
    }

    /**
     * @dev Generates a unique salt using a counter
     * @param baseSalt The base salt
     * @param counter The counter value
     * @return The generated salt
     */
    function generateUniqueSalt(
        bytes32 baseSalt,
        uint256 counter
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(baseSalt, counter));
    }

    /**
     * @dev Computes the address of a contract deployed with CREATE2
     * @param deployer The address that will deploy the contract
     * @param salt A salt to influence the contract address
     * @param bytecode The contract bytecode
     * @return The computed address
     */
    function computeAddress(
        address deployer,
        bytes32 salt,
        bytes memory bytecode
    ) internal pure returns (address) {
        bytes32 bytecodeHash = keccak256(bytecode);
        return Create2.computeAddress(deployer, salt, bytecodeHash);
    }
}
