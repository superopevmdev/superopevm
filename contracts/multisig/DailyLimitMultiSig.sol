// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {MultiSigWallet as MultiSigWallet} from "@superopevm/contracts/multisig/MultiSigWallet.sol";

/**
 * @title DailyLimitMultiSig
 * @dev Multi-signature wallet with daily withdrawal limit
 */
contract DailyLimitMultiSig is MultiSigWallet {
    // Daily limit settings
    uint256 public dailyLimit;
    uint256 public lastDay;
    uint256 public spentToday;

    // Events
    event DailyLimitChanged(uint256 newLimit);
    event SpentTodayUpdated(uint256 spent);

    /**
     * @dev Contract constructor sets initial owners and required number of confirmations
     * @param _owners List of initial owners
     * @param _required Number of required confirmations
     * @param _dailyLimit Daily withdrawal limit
     */
    constructor(
        address[] memory _owners,
        uint256 _required,
        uint256 _dailyLimit
    ) MultiSigWallet(_owners, _required) {
        dailyLimit = _dailyLimit;
        lastDay = block.timestamp / 86400;
    }

    /**
     * @dev Execute a transaction with daily limit check
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
        Transaction storage txn = transactions[transactionId];
        
        // Check daily limit for ether transfers
        if (txn.value > 0) {
            uint256 currentDay = block.timestamp / 86400;
            if (currentDay != lastDay) {
                lastDay = currentDay;
                spentToday = 0;
            }
            
            uint256 remaining = dailyLimit - spentToday;
            require(txn.value <= remaining, "DailyLimitMultiSig: daily limit exceeded");
            
            spentToday += txn.value;
            emit SpentTodayUpdated(spentToday);
        }
        
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
     * @dev Change daily limit
     * @param _dailyLimit New daily limit
     */
    function changeDailyLimit(uint256 _dailyLimit) external onlyOwner {
        dailyLimit = _dailyLimit;
        emit DailyLimitChanged(_dailyLimit);
    }

    /**
     * @dev Reset daily limit (owner only)
     */
    function resetSpentToday() external onlyOwner {
        spentToday = 0;
        emit SpentTodayUpdated(0);
    }
}
