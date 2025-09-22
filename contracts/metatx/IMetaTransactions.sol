// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IMetaTransactions
 * @dev Interface for Meta Transactions (EIP-2771)
 */
interface IMetaTransactions {
    /**
     * @dev Execute meta transaction
     */
    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory);
    
    /**
     * @dev Get nonce for meta transaction
     */
    function getNonce(address user) external view returns (uint256);
}
