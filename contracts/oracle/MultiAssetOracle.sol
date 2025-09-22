// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IOracle as IOracle} from "@superopevm/contracts/oracle/IOracle.sol";
import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";
import {Pausable as Pausable} from "@superopevm/contracts/security/Pausable.sol";

/**
 * @title MultiAssetOracle
 * @dev Oracle supporting multiple assets
 */
contract MultiAssetOracle is IOracle, Ownable, Pausable {
    // Asset data structure
    struct AssetData {
        string name;
        string symbol;
        uint8 decimals;
        mapping(uint256 => int256) priceHistory;
        uint256 latestTimestamp;
        bool active;
    }

    // Asset registry
    mapping(bytes32 => AssetData) public assets;
    bytes32[] public assetList;

    // Events
    event AssetAdded(bytes32 indexed assetId, string name, string symbol);
    event PriceUpdated(bytes32 indexed assetId, int256 newPrice, uint256 timestamp);
    event AssetRemoved(bytes32 indexed assetId);

    /**
     * @dev Add a new asset (owner only)
     */
    function addAsset(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external onlyOwner whenNotPaused returns (bytes32) {
        bytes32 assetId = keccak256(abi.encodePacked(name, symbol));
        
        require(!assets[assetId].active, "MultiAssetOracle: asset already exists");
        
        assets[assetId].name = name;
        assets[assetId].symbol = symbol;
        assets[assetId].decimals = decimals;
        assets[assetId].active = true;
        
        assetList.push(assetId);
        emit AssetAdded(assetId, name, symbol);
        
        return assetId;
    }

    /**
     * @dev Remove an asset (owner only)
     */
    function removeAsset(bytes32 assetId) external onlyOwner whenNotPaused {
        require(assets[assetId].active, "MultiAssetOracle: asset not found");
        
        assets[assetId].active = false;
        emit AssetRemoved(assetId);
    }

    /**
     * @dev Update price for an asset (owner only)
     */
    function updatePrice(
        bytes32 assetId,
        int256 newPrice
    ) external onlyOwner whenNotPaused {
        require(assets[assetId].active, "MultiAssetOracle: asset not found");
        
        uint256 currentTimestamp = block.timestamp;
        assets[assetId].priceHistory[currentTimestamp] = newPrice;
        assets[assetId].latestTimestamp = currentTimestamp;
        
        emit PriceUpdated(assetId, newPrice, currentTimestamp);
    }

    /**
     * @dev Get the latest price for an asset
     */
    function latestPrice() external view override whenNotPaused returns (int256) {
        revert("MultiAssetOracle: use asset-specific functions");
    }

    /**
     * @dev Get latest price for specific asset
     */
    function getLatestPrice(bytes32 assetId) external view whenNotPaused returns (int256) {
        require(assets[assetId].active, "MultiAssetOracle: asset not found");
        uint256 timestamp = assets[assetId].latestTimestamp;
        return assets[assetId].priceHistory[timestamp];
    }

    /**
     * @dev Get price at a specific timestamp for an asset
     */
    function getPriceAt(uint256 timestamp) external view override returns (int256) {
        revert("MultiAssetOracle: use asset-specific functions");
    }

    /**
     * @dev Get price at timestamp for specific asset
     */
    function getPriceAtForAsset(
        bytes32 assetId,
        uint256 timestamp
    ) external view returns (int256) {
        require(assets[assetId].active, "MultiAssetOracle: asset not found");
        return assets[assetId].priceHistory[timestamp];
    }

    /**
     * @dev Check if oracle is active
     */
    function isActive() external view override returns (bool) {
        return !paused();
    }

    /**
     * @dev Get asset information
     */
    function getAssetInfo(bytes32 assetId)
        external
        view
        returns (
            string memory,
            string memory,
            uint8
        )
    {
        require(assets[assetId].active, "MultiAssetOracle: asset not found");
        return (
            assets[assetId].name,
            assets[assetId].symbol,
            assets[assetId].decimals
        );
    }

    /**
     * @dev Get all active assets
     */
    function getActiveAssets() external view returns (bytes32[] memory) {
        bytes32[] memory activeAssets = new bytes32[](assetList.length);
        uint256 count = 0;
        
        for (uint256 i = 0; i < assetList.length; i++) {
            if (assets[assetList[i]].active) {
                activeAssets[count] = assetList[i];
                count++;
            }
        }
        
        // Resize array to actual count
        assembly {
            mstore(activeAssets, count)
        }
        
        return activeAssets;
    }
}
