// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IOracle
 * @dev Interface for oracle contracts
 */
interface IOracle {
    /**
     * @dev Get the latest price data
     */
    function latestPrice() external view returns (int256);

    /**
     * @dev Get price at a specific timestamp
     */
    function getPriceAt(uint256 timestamp) external view returns (int256);

    /**
     * @dev Check if oracle is active
     */
    function isActive() external view returns (bool);
}
