// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {MetaTransactions as MetaTransactions} from "@superopevm/contracts/metatx/MetaTransactions.sol";

/**
 * @title NativeMetaTransactions
 * @dev Enhanced Meta Transactions with native context extraction
 */
abstract contract NativeMetaTransactions is MetaTransactions {
    // Meta transaction context
    struct MetaTxContext {
        address sender;
        bytes data;
    }
    
    // Current meta transaction context
    MetaTxContext private _currentMetaTx;
    
    /**
     * @dev Execute meta transaction with context
     */
    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable override returns (bytes memory) {
        // Set context
        _currentMetaTx = MetaTxContext({
            sender: userAddress,
            data: functionSignature
        });
        
        // Execute meta transaction
        bytes memory result = super.executeMetaTransaction(
            userAddress,
            functionSignature,
            sigR,
            sigS,
            sigV
        );
        
        // Clear context
        delete _currentMetaTx;
        
        return result;
    }
    
    /**
     * @dev Get meta transaction sender
     */
    function _getMetaTxSender() internal view override returns (address) {
        return _currentMetaTx.sender;
    }
    
    /**
     * @dev Get meta transaction data
     */
    function _getMetaTxData() internal view override returns (bytes calldata) {
        return bytes(_currentMetaTx.data);
    }
}
