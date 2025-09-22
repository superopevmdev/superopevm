// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IMultiSig as IMultiSig} from "@superopevm/contracts/multisig/IMultiSig.sol";
import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";
import {ReentrancyGuard as ReentrancyGuard} from "@superopevm/contracts/security/ReentrancyGuard.sol";

/**
 * @title MultiSigWallet
 * @dev Multi-signature wallet contract
 */
contract MultiSigWallet is IMultiSig, Ownable, ReentrancyGuard {
    // State variables
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;
    mapping(address => bool) public isOwner;
    address[] public owners;
    uint256 public required;
    uint256 public _transactionCount;

    // Events
    event Submission(uint256 indexed transactionId);
    event Confirmation(address indexed owner, uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event Revocation(address indexed owner, uint256 indexed transactionId);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 required);

    // Modifiers
    modifier onlyWallet() {
        require(msg.sender == address(this), "MultiSigWallet: caller is not wallet");
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner], "MultiSigWallet: owner already exists");
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner], "MultiSigWallet: owner does not exist");
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        require(
            transactions[transactionId].destination != address(0),
            "MultiSigWallet: transaction does not exist"
        );
        _;
    }

    modifier confirmed(uint256 transactionId, address owner) {
        require(
            confirmations[transactionId][owner],
            "MultiSigWallet: transaction not confirmed"
        );
        _;
    }

    modifier notConfirmed(uint256 transactionId, address owner) {
        require(
            !confirmations[transactionId][owner],
            "MultiSigWallet: transaction already confirmed"
        );
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        require(
            !transactions[transactionId].executed,
            "MultiSigWallet: transaction already executed"
        );
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0), "MultiSigWallet: address is null");
        _;
    }

    modifier validRequirement(uint256 ownerCount, uint256 _required) {
        require(
            ownerCount > 0 && ownerCount <= 20 && _required > 0 && _required <= ownerCount,
            "MultiSigWallet: invalid requirement"
        );
        _;
    }

    /**
     * @dev Contract constructor sets initial owners and required number of confirmations
     * @param _owners List of initial owners
     * @param _required Number of required confirmations
     */
    constructor(address[] memory _owners, uint256 _required)
        validRequirement(_owners.length, _required)
    {
        for (uint256 i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "MultiSigWallet: invalid owner");
            require(!isOwner[_owners[i]], "MultiSigWallet: duplicate owner");
            isOwner[_owners[i]] = true;
            owners.push(_owners[i]);
        }
        required = _required;
    }

    /**
     * @dev Fallback function allows to deposit ether
     */
    receive() external payable {}

    /**
     * @dev Submit a new transaction
     * @param destination Transaction target address
     * @param value Transaction ether value
     * @param data Transaction data payload
     * @return transactionId Transaction ID
     */
    function submitTransaction(
        address destination,
        uint256 value,
        bytes calldata data
    ) external override onlyOwner returns (uint256 transactionId) {
        transactionId = _transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false,
            confirmations: 0
        });
        _transactionCount += 1;
        emit Submission(transactionId);
    }

    /**
     * @dev Confirm a transaction
     * @param transactionId Transaction ID
     */
    function confirmTransaction(uint256 transactionId)
        external
        override
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = true;
        transactions[transactionId].confirmations += 1;
        emit Confirmation(msg.sender, transactionId);
    }

    /**
     * @dev Execute a confirmed transaction
     * @param transactionId Transaction ID
     */
    function executeTransaction(uint256 transactionId)
        external
        override
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notExecuted(transactionId)
    {
        require(
            transactions[transactionId].confirmations >= required,
            "MultiSigWallet: insufficient confirmations"
        );
        Transaction storage txn = transactions[transactionId];
        txn.executed = true;
        (bool success, ) = txn.destination.call{value: txn.value}(txn.data);
        if (success) {
            emit Execution(transactionId);
        } else {
            emit ExecutionFailure(transactionId);
            txn.executed = false;
        }
    }

    /**
     * @dev Revoke confirmation for a transaction
     * @param transactionId Transaction ID
     */
    function revokeConfirmation(uint256 transactionId)
        external
        override
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        transactions[transactionId].confirmations -= 1;
        emit Revocation(msg.sender, transactionId);
    }

    /**
     * @dev Add a new owner
     * @param owner Address of new owner
     */
    function addOwner(address owner)
        external
        override
        onlyOwner
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

    /**
     * @dev Remove an owner
     * @param owner Address of owner to remove
     */
    function removeOwner(address owner)
        external
        override
        onlyOwner
        ownerExists(owner)
    {
        require(owners.length > 1, "MultiSigWallet: cannot remove last owner");
        isOwner[owner] = false;
        for (uint256 i = 0; i < owners.length - 1; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        owners.pop();
        if (required > owners.length) {
            _changeRequirement(owners.length);
        }
        emit OwnerRemoval(owner);
    }

    /**
     * @dev Replace an owner with a new owner
     * @param oldOwner Address of owner to be replaced
     * @param newOwner Address of new owner
     */
    function replaceOwner(address oldOwner, address newOwner)
        external
        override
        onlyOwner
        ownerExists(oldOwner)
        ownerDoesNotExist(newOwner)
        notNull(newOwner)
    {
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == oldOwner) {
                owners[i] = newOwner;
                break;
            }
        }
        isOwner[oldOwner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(oldOwner);
        emit OwnerAddition(newOwner);
    }

    /**
     * @dev Change required number of confirmations
     * @param _required New required number of confirmations
     */
    function changeRequirement(uint256 _required)
        external
        override
        onlyOwner
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }
    
    /**
     * @dev Internal function to change required number of confirmations
     */
    function _changeRequirement(uint256 _required) internal {
        // BARIS DI BAWAH INI YANG DIUBAH
        require(
            owners.length > 0 && owners.length <= 20 && _required > 0 && _required <= owners.length,
            "MultiSigWallet: invalid requirement"
        );
        required = _required;
        emit RequirementChange(_required);
    }

    /**
     * @dev Get transaction count
     * @return Number of transactions
     */
    function transactionCount() external view override returns (uint256) {
        return _transactionCount;
    }

    /**
     * @dev Get owners
     * @return List of owners
     */
    function getOwners() external view override returns (address[] memory) {
        return owners;
    }

    /**
     * @dev Get transaction details
     * @param transactionId Transaction ID
     * @return destination Transaction target address
     * @return value Transaction ether value
     * @return data Transaction data payload
     * @return executed Transaction execution status
     * @return _confirmations Number of confirmations
     */
    function getTransaction(uint256 transactionId)
        external
        view
        override
        returns (
            address destination,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 _confirmations
        )
    {
        Transaction storage txn = transactions[transactionId];
        return (
            txn.destination,
            txn.value,
            txn.data,
            txn.executed,
            txn.confirmations
        );
    }

    /**
     * @dev Check if transaction is confirmed by owner
     * @param transactionId Transaction ID
     * @param owner Owner address
     * @return Confirmation status
     */
    function isConfirmed(uint256 transactionId, address owner)
        external
        view
        override
        returns (bool)
    {
        return confirmations[transactionId][owner];
    }
}
