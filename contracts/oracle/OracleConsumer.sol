// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IOracle as IOracle} from "@superopevm/contracts/oracle/IOracle.sol";
import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";
import {Pausable as Pausable} from "@superopevm/contracts/security/Pausable.sol";

/**
 * @title OracleConsumer
 * @dev Contract that consumes oracle data
 */
contract OracleConsumer is Ownable, Pausable {
    // Oracle reference
    IOracle public oracle;

    // Events
    event OracleUpdated(address indexed newOracle);
    event PriceDataReceived(int256 price, uint256 timestamp);

    constructor(address oracleAddress) {
        _setOracle(oracleAddress);
    }

    /**
     * @dev Set oracle (owner only)
     */
    function setOracle(address oracleAddress) external onlyOwner {
        _setOracle(oracleAddress);
    }

    /**
     * @dev Internal oracle setter
     */
    function _setOracle(address oracleAddress) internal {
        require(oracleAddress != address(0), "OracleConsumer: invalid oracle");
        oracle = IOracle(oracleAddress);
        emit OracleUpdated(oracleAddress);
    }

    /**
     * @dev Get latest price from oracle
     */
    function getLatestPrice() external whenNotPaused returns (int256) {
        require(oracle.isActive(), "OracleConsumer: oracle inactive");
        int256 price = oracle.latestPrice();
        emit PriceDataReceived(price, block.timestamp);
        return price;
    }

    /**
     * @dev Get historical price from oracle
     */
    function getHistoricalPrice(uint256 timestamp) external whenNotPaused returns (int256) {
        require(oracle.isActive(), "OracleConsumer: oracle inactive");
        return oracle.getPriceAt(timestamp);
    }

    /**
     * @dev Execute action based on oracle price
     */
    function executeWithPrice(int256 threshold) external whenNotPaused {
        require(oracle.isActive(), "OracleConsumer: oracle inactive");
        int256 price = oracle.latestPrice();
        
        if (price >= threshold) {
            // Execute high price action
            _handleHighPrice(price);
        } else {
            // Execute low price action
            _handleLowPrice(price);
        }
    }

    /**
     * @dev Handle high price scenario (to be implemented)
     */
    function _handleHighPrice(int256 price) internal virtual {
        // Default implementation does nothing
    }

    /**
     * @dev Handle low price scenario (to be implemented)
     */
    function _handleLowPrice(int256 price) internal virtual {
        // Default implementation does nothing
    }
}
