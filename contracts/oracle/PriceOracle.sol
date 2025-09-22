// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IOracle as IOracle} from "@superopevm/contracts/oracle/IOracle.sol";
import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";
import {Pausable as Pausable} from "@superopevm/contracts/security/Pausable.sol";

/**
 * @title PriceOracle
 * @dev Simple price oracle implementation
 */
contract PriceOracle is IOracle, Ownable, Pausable {
    // Price data structure
    struct PriceData {
        int256 price;
        uint256 timestamp;
        bool active;
    }

    // Price history
    mapping(uint256 => PriceData) public priceHistory;
    uint256 public latestTimestamp;

    // Asset information
    string public assetName;
    string public assetSymbol;
    uint8 public assetDecimals;

    // Events
    event PriceUpdated(int256 newPrice, uint256 timestamp);
    event OracleActivated(bool isActive);

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        int256 initialPrice
    ) {
        assetName = name;
        assetSymbol = symbol;
        assetDecimals = decimals;
        _updatePrice(initialPrice);
    }

    /**
     * @dev Get the latest price data
     */
    function latestPrice() external view override whenNotPaused returns (int256) {
        return priceHistory[latestTimestamp].price;
    }

    /**
     * @dev Get price at a specific timestamp
     */
    function getPriceAt(uint256 timestamp) external view override returns (int256) {
        require(priceHistory[timestamp].active, "PriceOracle: no data at timestamp");
        return priceHistory[timestamp].price;
    }

    /**
     * @dev Check if oracle is active
     */
    function isActive() external view override returns (bool) {
        return !paused();
    }

    /**
     * @dev Update price (owner only)
     */
    function updatePrice(int256 newPrice) external onlyOwner whenNotPaused {
        _updatePrice(newPrice);
    }

    /**
     * @dev Internal price update function
     */
    function _updatePrice(int256 newPrice) internal {
        uint256 currentTimestamp = block.timestamp;
        
        priceHistory[currentTimestamp] = PriceData({
            price: newPrice,
            timestamp: currentTimestamp,
            active: true
        });
        
        latestTimestamp = currentTimestamp;
        emit PriceUpdated(newPrice, currentTimestamp);
    }

    /**
     * @dev Pause oracle (owner only)
     */
    function pauseOracle() external onlyOwner {
        _pause();
        emit OracleActivated(false);
    }

    /**
     * @dev Unpause oracle (owner only)
     */
    function unpauseOracle() external onlyOwner {
        _unpause();
        emit OracleActivated(true);
    }

    /**
     * @dev Get asset information
     */
    function getAssetInfo()
        external
        view
        returns (
            string memory,
            string memory,
            uint8
        )
    {
        return (assetName, assetSymbol, assetDecimals);
    }
}
