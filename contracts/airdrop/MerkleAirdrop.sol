// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IMerkleAirdrop as IMerkleAirdrop} from "@superopevm/contracts/airdrop/IMerkleAirdrop.sol";
import {IERC20 as IERC20} from "@superopevm/contracts/token/ERC20/IERC20.sol";
import {MerkleProof as MerkleProof} from "@superopevm/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";
import {Pausable as Pausable} from "@superopevm/contracts/security/Pausable.sol";

/**
 * @title MerkleAirdrop
 * @dev Merkle-based token airdrop contract
 */
contract MerkleAirdrop is IMerkleAirdrop, Ownable, Pausable {
    // Token being distributed
    IERC20 public immutable token;
    
    // Merkle root
    bytes32 public immutable merkleRoot;
    
    // Claim tracking
    mapping(address => bool) public claimed;
    
    // Events
    event Claimed(address indexed account, uint256 amount);
    event MerkleRootUpdated(bytes32 newRoot);
    
    constructor(
        address token_,
        bytes32 merkleRoot_
    ) {
        token = IERC20(token_);
        merkleRoot = merkleRoot_;
    }
    
    /**
     * @dev Claim tokens from airdrop
     */
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external whenNotPaused {
        require(!claimed[account], "MerkleAirdrop: Already claimed");
        require(verifyClaim(index, account, amount, merkleProof), "MerkleAirdrop: Invalid proof");
        
        claimed[account] = true;
        token.transfer(account, amount);
        emit Claimed(account, amount);
    }
    
    /**
     * @dev Verify claim validity
     */
    function verifyClaim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(index, account, amount));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }
    
    /**
     * @dev Check if address has claimed
     */
    function hasClaimed(address account) external view returns (bool) {
        return claimed[account];
    }
    
    /**
     * @dev Update merkle root (owner only)
     */
    function updateMerkleRoot(bytes32 newRoot) external onlyOwner {
        merkleRoot = newRoot;
        emit MerkleRootUpdated(newRoot);
    }
    
    /**
     * @dev Rescue tokens (owner only)
     */
    function rescueTokens(uint256 amount) external onlyOwner {
        token.transfer(owner(), amount);
    }
}
