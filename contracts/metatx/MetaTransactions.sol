// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IMetaTransactions as IMetaTransactions} from "@superopevm/contracts/metatx/IMetaTransactions.sol";
import {ECDSA as ECDSA} from "@superopevm/contracts/utils/cryptography/ECDSA.sol";
import {EIP712 as EIP712} from "@superopevm/contracts/utils/cryptography/EIP712.sol";
import {Context as Context} from "@superopevm/contracts/utils/Context.sol";

/**
 * @title MetaTransactions
 * @dev Implementation of Meta Transactions (EIP-2771)
 */
abstract contract MetaTransactions is IMetaTransactions, EIP712, Context {
    // Nonce management
    mapping(address => uint256) public nonces;
    
    // EIP-712 typehash
    bytes32 private constant _META_TX_TYPEHASH = 
        keccak256(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        );
    
    constructor() EIP712("MetaTransactions", "1") {}
    
    /**
     * @dev Execute meta transaction
     */
    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable override returns (bytes memory) {
        // Verify signature
        bytes32 metaTxHash = _hashMetaTransaction(
            nonces[userAddress]++,
            userAddress,
            functionSignature
        );
        
        address signer = ECDSA.recover(metaTxHash, sigV, sigR, sigS);
        require(signer == userAddress, "MetaTransactions: invalid signature");
        
        // Execute function
        (bool success, bytes memory result) = address(this).call(functionSignature);
        require(success, "MetaTransactions: execution failed");
        
        return result;
    }
    
    /**
     * @dev Get nonce for meta transaction
     */
    function getNonce(address user) external view override returns (uint256) {
        return nonces[user];
    }
    
    /**
     * @dev Hash meta transaction
     */
    function _hashMetaTransaction(
        uint256 nonce,
        address from,
        bytes memory functionSignature
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                _META_TX_TYPEHASH,
                nonce,
                from,
                keccak256(functionSignature)
            )
        );
        
        return _hashTypedDataV4(structHash);
    }
    
    /**
     * @dev Extract sender from meta transaction context
     */
    function _msgSender() internal view override returns (address) {
        if (msg.sender == address(this)) {
            // Meta transaction context
            return _getMetaTxSender();
        }
        return super._msgSender();
    }
    
    /**
     * @dev Extract data from meta transaction context
     */
    function _msgData() internal view override returns (bytes calldata) {
        if (msg.sender == address(this)) {
            // Meta transaction context
            return _getMetaTxData();
        }
        return super._msgData();
    }
    
    /**
     * @dev Get meta transaction sender (to be implemented)
     */
    function _getMetaTxSender() internal view virtual returns (address) {
        return address(0);
    }
    
    /**
     * @dev Get meta transaction data (to be implemented)
     */
    function _getMetaTxData() internal view virtual returns (bytes calldata) {
        return bytes("");
    }
}
