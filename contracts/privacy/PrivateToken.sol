// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20 as IERC20} from "@superopevm/contracts/token/ERC20/IERC20.sol";
import {IZKVerifier as IZKVerifier} from "@superopevm/contracts/privacy/IZKVerifier.sol";
import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";
import {ReentrancyGuard as ReentrancyGuard} from "@superopevm/contracts/security/ReentrancyGuard.sol";

/**
 * @title PrivateToken
 * @dev ERC20 token with private transfers using Zero-Knowledge Proofs
 */
contract PrivateToken is Ownable, ReentrancyGuard {
    // Token interface
    IERC20 public token;
    
    // ZK Verifier
    IZKVerifier public verifier;
    
    // Commitment registry
    mapping(bytes32 => bool) public commitments;
    mapping(bytes32 => bool) public nullifiers;
    
    // Events
    event Deposit(address indexed from, uint256 amount, bytes32 indexed commitment);
    event Withdraw(address indexed to, uint256 amount, bytes32 indexed nullifier);
    event Transfer(bytes32 indexed inputCommitment, bytes32 indexed outputCommitment);
    
    constructor(
        address tokenAddress,
        address verifierAddress
    ) {
        token = IERC20(tokenAddress);
        verifier = IZKVerifier(verifierAddress);
    }
    
    /**
     * @dev Deposit tokens into the private pool
     */
    function deposit(uint256 amount, bytes32 commitment) external nonReentrant {
        require(amount > 0, "PrivateToken: amount must be > 0");
        require(!commitments[commitment], "PrivateToken: commitment exists");
        
        // Transfer tokens to this contract
        require(token.transferFrom(msg.sender, address(this), amount), "PrivateToken: transfer failed");
        
        // Record commitment
        commitments[commitment] = true;
        
        emit Deposit(msg.sender, amount, commitment);
    }
    
    /**
     * @dev Withdraw tokens from the private pool
     */
    function withdraw(
        address to,
        uint256 amount,
        bytes32 nullifier,
        bytes calldata proof,
        bytes calldata publicInputs
    ) external nonReentrant {
        require(to != address(0), "PrivateToken: invalid recipient");
        require(amount > 0, "PrivateToken: amount must be > 0");
        require(!nullifiers[nullifier], "PrivateToken: nullifier exists");
        
        // Verify the ZK proof
        require(verifier.verifyProof(proof, publicInputs), "PrivateToken: invalid proof");
        
        // Record nullifier to prevent double spending
        nullifiers[nullifier] = true;
        
        // Transfer tokens
        require(token.transfer(to, amount), "PrivateToken: transfer failed");
        
        emit Withdraw(to, amount, nullifier);
    }
    
    /**
     * @dev Private transfer between commitments
     */
    function privateTransfer(
        bytes32 inputCommitment,
        bytes32 outputCommitment,
        bytes32 nullifier,
        bytes calldata proof,
        bytes calldata publicInputs
    ) external nonReentrant {
        require(commitments[inputCommitment], "PrivateToken: input commitment not found");
        require(!commitments[outputCommitment], "PrivateToken: output commitment exists");
        require(!nullifiers[nullifier], "PrivateToken: nullifier exists");
        
        // Verify the ZK proof
        require(verifier.verifyProof(proof, publicInputs), "PrivateToken: invalid proof");
        
        // Update state
        commitments[inputCommitment] = false;
        commitments[outputCommitment] = true;
        nullifiers[nullifier] = true;
        
        emit Transfer(inputCommitment, outputCommitment);
    }
    
    /**
     * @dev Rescue tokens (owner only)
     */
    function rescueTokens(uint256 amount) external onlyOwner {
        require(token.transfer(owner(), amount), "PrivateToken: transfer failed");
    }
}
