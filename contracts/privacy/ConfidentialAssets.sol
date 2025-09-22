// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20 as IERC20} from "@superopevm/contracts/token/ERC20/IERC20.sol";
import {IZKVerifier as IZKVerifier} from "@superopevm/contracts/privacy/IZKVerifier.sol";
import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";
import {ReentrancyGuard as ReentrancyGuard} from "@superopevm/contracts/security/ReentrancyGuard.sol";

/**
 * @title ConfidentialAssets
 * @dev Confidential asset management using Zero-Knowledge Proofs
 */
contract ConfidentialAssets is Ownable, ReentrancyGuard {
    // Asset structure
    struct Asset {
        address token;
        uint256 totalSupply;
        mapping(bytes32 => uint256) balances;
        mapping(bytes32 => bool) nullifiers;
    }
    
    // ZK Verifier
    IZKVerifier public verifier;
    
    // Assets registry
    mapping(bytes32 => Asset) public assets;
    bytes32[] public assetList;
    
    // Events
    event AssetCreated(bytes32 indexed assetId, address indexed token);
    event Minted(bytes32 indexed assetId, bytes32 indexed commitment, uint256 amount);
    event Transferred(bytes32 indexed assetId, bytes32 inputNullifier, bytes32 outputCommitment);
    event Burned(bytes32 indexed assetId, bytes32 indexed nullifier, uint256 amount);
    
    constructor(address verifierAddress) {
        verifier = IZKVerifier(verifierAddress);
    }
    
    /**
     * @dev Create a new confidential asset
     */
    function createAsset(address tokenAddress) external onlyOwner returns (bytes32) {
        require(tokenAddress != address(0), "ConfidentialAssets: invalid token");
        
        bytes32 assetId = keccak256(abi.encodePacked(tokenAddress, block.timestamp));
        assets[assetId].token = tokenAddress;
        assetList.push(assetId);
        
        emit AssetCreated(assetId, tokenAddress);
        return assetId;
    }
    
    /**
     * @dev Mint confidential tokens
     */
    function mint(
        bytes32 assetId,
        uint256 amount,
        bytes32 commitment,
        bytes calldata proof,
        bytes calldata publicInputs
    ) external nonReentrant {
        Asset storage asset = assets[assetId];
        require(asset.token != address(0), "ConfidentialAssets: asset not found");
        require(amount > 0, "ConfidentialAssets: amount must be > 0");
        require(!asset.balances[commitment], "ConfidentialAssets: commitment exists");
        
        // Verify the ZK proof
        require(verifier.verifyProof(proof, publicInputs), "ConfidentialAssets: invalid proof");
        
        // Transfer tokens to this contract
        require(
            IERC20(asset.token).transferFrom(msg.sender, address(this), amount),
            "ConfidentialAssets: transfer failed"
        );
        
        // Update state
        asset.totalSupply += amount;
        asset.balances[commitment] = amount;
        
        emit Minted(assetId, commitment, amount);
    }
    
    /**
     * @dev Transfer confidential tokens
     */
    function transfer(
        bytes32 assetId,
        bytes32 inputCommitment,
        bytes32 outputCommitment,
        bytes32 nullifier,
        bytes calldata proof,
        bytes calldata publicInputs
    ) external nonReentrant {
        Asset storage asset = assets[assetId];
        require(asset.token != address(0), "ConfidentialAssets: asset not found");
        require(asset.balances[inputCommitment] > 0, "ConfidentialAssets: input commitment not found");
        require(!asset.balances[outputCommitment], "ConfidentialAssets: output commitment exists");
        require(!asset.nullifiers[nullifier], "ConfidentialAssets: nullifier exists");
        
        // Verify the ZK proof
        require(verifier.verifyProof(proof, publicInputs), "ConfidentialAssets: invalid proof");
        
        // Get amount from input commitment
        uint256 amount = asset.balances[inputCommitment];
        
        // Update state
        asset.balances[inputCommitment] = 0;
        asset.balances[outputCommitment] = amount;
        asset.nullifiers[nullifier] = true;
        
        emit Transferred(assetId, inputNullifier, outputCommitment);
    }
    
    /**
     * @dev Burn confidential tokens
     */
    function burn(
        bytes32 assetId,
        bytes32 nullifier,
        uint256 amount,
        bytes calldata proof,
        bytes calldata publicInputs
    ) external nonReentrant {
        Asset storage asset = assets[assetId];
        require(asset.token != address(0), "ConfidentialAssets: asset not found");
        require(amount > 0, "ConfidentialAssets: amount must be > 0");
        require(!asset.nullifiers[nullifier], "ConfidentialAssets: nullifier exists");
        
        // Verify the ZK proof
        require(verifier.verifyProof(proof, publicInputs), "ConfidentialAssets: invalid proof");
        
        // Update state
        asset.totalSupply -= amount;
        asset.nullifiers[nullifier] = true;
        
        // Transfer tokens to sender
        require(
            IERC20(asset.token).transfer(msg.sender, amount),
            "ConfidentialAssets: transfer failed"
        );
        
        emit Burned(assetId, nullifier, amount);
    }
    
    /**
     * @dev Get asset information
     */
    function getAsset(bytes32 assetId) external view returns (address, uint256) {
        Asset storage asset = assets[assetId];
        return (asset.token, asset.totalSupply);
    }
    
    /**
     * @dev Get all assets
     */
    function getAllAssets() external view returns (bytes32[] memory) {
        return assetList;
    }
}
