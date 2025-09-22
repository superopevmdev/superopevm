// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title Multicall2
 * @dev Enhanced version of Multicall with block number support
 */
contract Multicall2 {
    /**
     * @dev Aggregate multiple calls into a single call
     * @param requireSuccess If true, revert on any failure
     * @param calls Array of call data
     * @return blockNumber Current block number
     * @return returnData Array of return data
     */
    function aggregate(
        bool requireSuccess,
        Call[] calldata calls
    ) public returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = calls[i].target.call(calls[i].callData);
            
            if (!success && requireSuccess) {
                assembly {
                    revert(add(result, 0x20), mload(result))
                }
            }
            
            returnData[i] = result;
        }
    }

    struct Call {
        address target;
        bytes callData;
    }
}
