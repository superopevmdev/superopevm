// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title Multicall3
 * @dev Advanced multicall with tryAggregate support
 */
contract Multicall3 {
    /**
     * @dev Aggregate multiple calls into a single call
     * @param requireSuccess If true, revert on any failure
     * @param calls Array of call data
     * @return blockNumber Current block number
     * @return returnData Array of return data
     */
    function aggregate(
        bool requireSuccess,
        Call3[] calldata calls
    ) public payable returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        
        for (uint256 i = 0; i < calls.length; i++) {
            Call3 memory call = calls[i];
            (bool success, bytes memory result) = call.target.call{value: call.value}(call.callData);
            
            if (!success && requireSuccess) {
                assembly {
                    revert(add(result, 0x20), mload(result))
                }
            }
            
            returnData[i] = result;
        }
    }

    /**
     * @dev Aggregate calls with tryAggregate pattern
     * @param requireSuccess If true, revert on any failure
     * @param calls Array of call data
     * @return blockNumber Current block number
     * @return returnData Array of Result structs
     */
    function tryAggregate(
        bool requireSuccess,
        Call3[] calldata calls
    ) public payable returns (uint256 blockNumber, Result[] memory returnData) {
        blockNumber = block.number;
        returnData = new Result[](calls.length);
        
        for (uint256 i = 0; i < calls.length; i++) {
            Call3 memory call = calls[i];
            (bool success, bytes memory result) = call.target.call{value: call.value}(call.callData);
            
            returnData[i] = Result(success, result);
            
            if (!success && requireSuccess) {
                assembly {
                    revert(add(result, 0x20), mload(result))
                }
            }
        }
    }

    /**
     * @dev Aggregate calls with tryAggregate pattern (no revert)
     * @param calls Array of call data
     * @return blockNumber Current block number
     * @return returnData Array of Result structs
     */
    function tryBlockAndAggregate(
        bool requireSuccess,
        Call3[] calldata calls
    ) public payable returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData) {
        blockNumber = block.number;
        blockHash = blockhash(block.number - 1);
        returnData = new Result[](calls.length);
        
        for (uint256 i = 0; i < calls.length; i++) {
            Call3 memory call = calls[i];
            (bool success, bytes memory result) = call.target.call{value: call.value}(call.callData);
            
            returnData[i] = Result(success, result);
            
            if (!success && requireSuccess) {
                assembly {
                    revert(add(result, 0x20), mload(result))
                }
            }
        }
    }

    struct Call3 {
        address target;
        bytes callData;
        uint256 value;
    }

    struct Result {
        bool success;
        bytes returnData;
    }
}
