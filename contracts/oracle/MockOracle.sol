// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IOracle as IOracle} from "@superopevm/contracts/oracle/IOracle.sol";

/**
 * @title MockOracle
 * @dev Mock oracle for testing purposes
 */
contract MockOracle is IOracle {
    int256 private _price;
    bool private _active = true;
    mapping(uint256 => int256) private _priceHistory;

    event PriceSet(int256 newPrice);
    event OracleStatusChanged(bool isActive);

    constructor(int256 initialPrice) {
        _price = initialPrice;
        _priceHistory[block.timestamp] = initialPrice;
    }

    /**
     * @dev Get the latest price data
     */
    function latestPrice() external view override returns (int256) {
        return _price;
    }

    /**
     * @dev Get price at a specific timestamp
     */
    function getPriceAt(uint256 timestamp) external view override returns (int256) {
        return _priceHistory[timestamp];
    }

    /**
     * @dev Check if oracle is active
     */
    function isActive() external view override returns (bool) {
        return _active;
    }

    /**
     * @dev Set price (for testing)
     */
    function setPrice(int256 newPrice) external {
        _price = newPrice;
        _priceHistory[block.timestamp] = newPrice;
        emit PriceSet(newPrice);
    }

    /**
     * @dev Set historical price (for testing)
     */
    function setHistoricalPrice(uint256 timestamp, int256 price) external {
        _priceHistory[timestamp] = price;
    }

    /**
     * @dev Set oracle status (for testing)
     */
    function setActive(bool active) external {
        _active = active;
        emit OracleStatusChanged(active);
    }

    /**
     * @dev Get current price (for testing)
     */
    function getCurrentPrice() external view returns (int256) {
        return _price;
    }
}
