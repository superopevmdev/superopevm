// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ZKVerifier as ZKVerifier} from "@superopevm/contracts/privacy/ZKVerifier.sol";

/**
 * @title Groth16Verifier
 * @dev Verifier for Groth16 zero-knowledge proofs
 */
contract Groth16Verifier is ZKVerifier {
    // Precompiled contract address for Groth16 verification (0x08 on mainnet)
    address public constant PRECOMPILE = 0x0000000000000000000000000000000000000008;
    
    constructor(bytes32 _vkHash) ZKVerifier(_vkHash) {}
    
    /**
     * @dev Internal function to verify Groth16 proof
     */
    function _verifyProof(
        bytes memory proof,
        bytes memory publicInputs
    ) internal override returns (bool) {
        // Call the precompiled contract
        (bool success, bytes memory result) = PRECOMPILE.staticcall(
            abi.encodePacked(proof, publicInputs)
        );
        
        // The precompile returns 0x01 for valid, 0x00 for invalid
        return success && result.length == 32 && result[31] == 0x01;
    }
}
