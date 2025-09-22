// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ECDSA as ECDSA} from "@superopevm/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title SignatureChecker
 * @dev Helper for verifying signatures
 */
library SignatureChecker {
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.recover(hash, signature);
        return (error == ECDSA.RecoverError.NoError && recovered == signer);
    }
    
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.recover(hash, v, r, s);
        return (error == ECDSA.RecoverError.NoError && recovered == signer);
    }
}
