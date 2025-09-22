// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IMultiSig
 * @dev Interface for Multi-signature wallet
 */
interface IMultiSig {
    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
    }

    /**
     * @dev Submit a new transaction
     */
    function submitTransaction(
        address destination,
        uint256 value,
        bytes calldata data
    ) external returns (uint256 transactionId);

    /**
     * @dev Confirm a transaction
     */
    function confirmTransaction(uint256 transactionId) external;

    /**
     * @dev Execute a confirmed transaction
     */
    function executeTransaction(uint256 transactionId) external;

    /**
     * @dev Revoke confirmation for a transaction
     */
    function revokeConfirmation(uint256 transactionId) external;

    /**
     * @dev Add a new owner
     */
    function addOwner(address owner) external;

    /**
     * @dev Remove an owner
     */
    function removeOwner(address owner) external;

    /**
     * @dev Replace an owner
     */
    function replaceOwner(address oldOwner, address newOwner) external;

    /**
     * @dev Change required confirmations
     */
    function changeRequirement(uint256 _required) external;

    /**
     * @dev Get transaction count
     */
    function transactionCount() external view returns (uint256);

    /**
     * @dev Get owners
     */
    function getOwners() external view returns (address[] memory);

    /**
     * @dev Get transaction details
     */
    function getTransaction(uint256 transactionId)
        external
        view
        returns (
            address destination,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 confirmations
        );

    /**
     * @dev Check if transaction is confirmed by owner
     */
    function isConfirmed(uint256 transactionId, address owner)
        external
        view
        returns (bool);
}
