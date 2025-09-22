// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title Multicall
 * @dev Aggregate multiple calls into a single call
 */
contract Multicall {
    /**
     * @dev Aggregate multiple calls into a single call
     * @param calls Array of call data
     * @return results Array of return data
     */
    function aggregate(bytes[] calldata calls) public returns (bytes[] memory results) {
        results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success) {
                assembly {
                    revert(add(result, 0x20), mload(result))
                }
            }
            results[i] = result;
        }
    }
}
