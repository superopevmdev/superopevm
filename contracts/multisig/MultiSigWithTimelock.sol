// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {MultiSigWallet as MultiSigWallet} from "@superopevm/contracts/multisig/MultiSigWallet.sol";

/**
 * @title MultiSigWithTimelock
 * @dev Multi-signature wallet with timelock for execution
 */
contract MultiSigWithTimelock is MultiSigWallet {
    // Timelock settings
    uint256 public timelock;
    mapping(uint256 => uint256) public executionTime;

    // Events
    event TimelockChanged(uint256 newTimelock);
    event TransactionTimeLocked(uint256 indexed transactionId, uint256 executionTime);

    /**
     * @dev Contract constructor sets initial owners and required number of confirmations
     * @param _owners List of initial owners
     * @param _required Number of required confirmations
     * @param _timelock Timelock period in seconds
     */
    constructor(
        address[] memory _owners,
        uint256 _required,
        uint256 _timelock
    ) MultiSigWallet(_owners, _required) {
        timelock = _timelock;
    }

    /**
     * @dev Confirm a transaction and set execution time
     * @param transactionId Transaction ID
     */
    function confirmTransaction(uint256 transactionId)
        public
        override
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = true;
        transactions[transactionId].confirmations += 1;
        
        // Set execution time when transaction gets enough confirmations
        if (transactions[transactionId].confirmations == required) {
            executionTime[transactionId] = block.timestamp + timelock;
            emit TransactionTimeLocked(transactionId, executionTime[transactionId]);
        }
        
        emit Confirmation(msg.sender, transactionId);
    }

    /**
     * @dev Execute a transaction after timelock
     * @param transactionId Transaction ID
     */
    function executeTransaction(uint256 transactionId)
        public
        override
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notExecuted(transactionId)
    {
        require(
            transactions[transactionId].confirmations >= required,
            "MultiSigWallet: insufficient confirmations"
        );
        require(
            block.timestamp >= executionTime[transactionId],
            "MultiSigWithTimelock: timelock not expired"
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
     * @dev Change timelock period
     * @param _timelock New timelock period in seconds
     */
    function changeTimelock(uint256 _timelock) external onlyOwner {
        timelock = _timelock;
        emit TimelockChanged(_timelock);
    }

    /**
     * @dev Get remaining time for transaction execution
     * @param transactionId Transaction ID
     * @return Remaining seconds until execution
     */
    function getRemainingTime(uint256 transactionId) external view returns (uint256) {
        if (executionTime[transactionId] <= block.timestamp) {
            return 0;
        }
        return executionTime[transactionId] - block.timestamp;
    }
}
