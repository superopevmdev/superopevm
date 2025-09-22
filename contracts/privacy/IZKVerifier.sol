// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IZKVerifier
 * @dev Interface for Zero-Knowledge Proof verifiers
 */
interface IZKVerifier {
    /**
     * @dev Verify a zero-knowledge proof
     * @param proof The encoded proof data
     * @param publicInputs The public inputs for the proof
     * @return True if the proof is valid
     */
    function verifyProof(
        bytes calldata proof,
        bytes calldata publicInputs
    ) external view returns (bool);
    
    /**
     * @dev Get the verification key hash
     * @return The hash of the verification key
     */
    function verificationKeyHash() external view returns (bytes32);
}
