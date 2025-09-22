// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IOracle as IOracle} from "@superopevm/contracts/oracle/IOracle.sol";
import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";
import {Pausable as Pausable} from "@superopevm/contracts/security/Pausable.sol";

/**
 * @title ChainlinkOracle
 * @dev Oracle wrapper for Chainlink price feeds
 */
contract ChainlinkOracle is IOracle, Ownable, Pausable {
    // Chainlink Aggregator interface
    interface AggregatorV3Interface {
        function latestRoundData()
            external
            view
            returns (
                uint80 roundId,
                int256 answer,
                uint256 startedAt,
                uint256 updatedAt,
                uint80 answeredInRound
            );
    }

    // Chainlink feed reference
    AggregatorV3Interface public priceFeed;

    // Asset information
    string public assetName;
    string public assetSymbol;
    uint8 public assetDecimals;

    // Events
    event PriceFeedUpdated(address indexed newFeed);
    event PriceDataReceived(int256 price, uint256 timestamp);

    constructor(
        address feedAddress,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) {
        _setPriceFeed(feedAddress);
        assetName = name;
        assetSymbol = symbol;
        assetDecimals = decimals;
    }

    /**
     * @dev Get the latest price data
     */
    function latestPrice() external view override whenNotPaused returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    /**
     * @dev Get price at a specific timestamp (not supported by Chainlink)
     */
    function getPriceAt(uint256 timestamp) external view override returns (int256) {
        revert("ChainlinkOracle: historical prices not supported");
    }

    /**
     * @dev Check if oracle is active
     */
    function isActive() external view override returns (bool) {
        return !paused();
    }

    /**
     * @dev Set price feed (owner only)
     */
    function setPriceFeed(address feedAddress) external onlyOwner {
        _setPriceFeed(feedAddress);
    }

    /**
     * @dev Internal price feed setter
     */
    function _setPriceFeed(address feedAddress) internal {
        require(feedAddress != address(0), "ChainlinkOracle: invalid feed");
        priceFeed = AggregatorV3Interface(feedAddress);
        emit PriceFeedUpdated(feedAddress);
    }

    /**
     * @dev Get latest price with timestamp
     */
    function latestPriceWithTimestamp()
        external
        view
        whenNotPaused
        returns (int256 price, uint256 timestamp)
    {
        (, price, , timestamp, ) = priceFeed.latestRoundData();
        return (price, timestamp);
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
