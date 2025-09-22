// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";
import {ReentrancyGuard as ReentrancyGuard} from "@superopevm/contracts/security/ReentrancyGuard.sol";

/**
 * @title BatchProcessor
 * @dev Contract for batch processing multiple transactions
 */
contract BatchProcessor is Ownable, ReentrancyGuard {
    struct Batch {
        address[] targets;
        bytes[] data;
        uint256[] values;
        bool executed;
        uint256 timestamp;
    }
    
    mapping(uint256 => Batch) public batches;
    uint256 public batchCount;
    
    event BatchCreated(uint256 indexed batchId, uint256 transactionCount);
    event BatchExecuted(uint256 indexed batchId, bool success);
    event BatchFailed(uint256 indexed batchId, uint256 failedIndex);
    
    function createBatch(
        address[] calldata targets,
        bytes[] calldata data,
        uint256[] calldata values
    ) external onlyOwner returns (uint256) {
        require(targets.length == data.length, "BatchProcessor: targets-data length mismatch");
        require(targets.length == values.length, "BatchProcessor: targets-values length mismatch");
        require(targets.length > 0, "BatchProcessor: empty batch");
        
        uint256 batchId = batchCount++;
        batches[batchId] = Batch({
            targets: targets,
            data: data,
            values: values,
            executed: false,
            timestamp: block.timestamp
        });
        
        emit BatchCreated(batchId, targets.length);
        return batchId;
    }
    
    function executeBatch(uint256 batchId) external nonReentrant onlyOwner {
        Batch storage batch = batches[batchId];
        require(!batch.executed, "BatchProcessor: batch already executed");
        
        bool allSuccess = true;
        for (uint256 i = 0; i < batch.targets.length; i++) {
            (bool success, ) = batch.targets[i].call{value: batch.values[i]}(batch.data[i]);
            if (!success) {
                allSuccess = false;
                emit BatchFailed(batchId, i);
            }
        }
        
        batch.executed = true;
        emit BatchExecuted(batchId, allSuccess);
    }
    
    function executeBatchWithValue(uint256 batchId) external payable nonReentrant onlyOwner {
        Batch storage batch = batches[batchId];
        require(!batch.executed, "BatchProcessor: batch already executed");
        
        uint256 totalValue = 0;
        for (uint256 i = 0; i < batch.values.length; i++) {
            totalValue += batch.values[i];
        }
        require(msg.value == totalValue, "BatchProcessor: incorrect value sent");
        
        bool allSuccess = true;
        for (uint256 i = 0; i < batch.targets.length; i++) {
            (bool success, ) = batch.targets[i].call{value: batch.values[i]}(batch.data[i]);
            if (!success) {
                allSuccess = false;
                emit BatchFailed(batchId, i);
            }
        }
        
        batch.executed = true;
        emit BatchExecuted(batchId, allSuccess);
    }
    
    function getBatch(uint256 batchId) external view returns (
        address[] memory targets,
        bytes[] memory data,
        uint256[] memory values,
        bool executed,
        uint256 timestamp
    ) {
        Batch storage batch = batches[batchId];
        return (
            batch.targets,
            batch.data,
            batch.values,
            batch.executed,
            batch.timestamp
        );
    }
    
    receive() external payable {}
}
