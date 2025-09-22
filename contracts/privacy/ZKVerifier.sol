// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IZKVerifier as IZKVerifier} from "@superopevm/contracts/privacy/IZKVerifier.sol";
import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";

/**
 * @title ZKVerifier
 * @dev Base contract for Zero-Knowledge Proof verifiers
 */
abstract contract ZKVerifier is IZKVerifier, Ownable {
    // Verification key hash
    bytes32 public immutable vkHash;
    
    // Events
    event ProofVerified(bool indexed result, bytes32 indexed proofHash);
    event VerificationKeyUpdated(bytes32 indexed newVkHash);
    
    constructor(bytes32 _vkHash) {
        vkHash = _vkHash;
    }
    
    /**
     * @dev Get the verification key hash
     */
    function verificationKeyHash() external view override returns (bytes32) {
        return vkHash;
    }
    
    /**
     * @dev Internal function to verify proof (to be implemented)
     */
    function _verifyProof(
        bytes memory proof,
        bytes memory publicInputs
    ) internal virtual returns (bool);
    
    /**
     * @dev Verify a zero-knowledge proof
     */
    function verifyProof(
        bytes calldata proof,
        bytes calldata publicInputs
    ) external view override returns (bool) {
        bool result = _verifyProof(proof, publicInputs);
        emit ProofVerified(result, keccak256(proof));
        return result;
    }
}
