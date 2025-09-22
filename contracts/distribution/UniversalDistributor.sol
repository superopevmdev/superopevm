// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20 as IERC20} from "@superopevm/contracts/token/ERC20/IERC20.sol";
import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";
import {Pausable as Pausable} from "@superopevm/contracts/security/Pausable.sol";
import {ReentrancyGuard as ReentrancyGuard} from "@superopevm/contracts/security/ReentrancyGuard.sol";

/**
 * @title UniversalDistributor
 * @dev Distribute both native and ERC20 tokens
 */
contract UniversalDistributor is Ownable, Pausable, ReentrancyGuard {
    // Events
    event NativeDistributed(address indexed recipient, uint256 amount);
    event ERC20Distributed(address indexed token, address indexed recipient, uint256 amount);
    event BatchNativeDistributed(uint256 totalRecipients, uint256 totalAmount);
    event BatchERC20Distributed(address indexed token, uint256 totalRecipients, uint256 totalAmount);
    
    /**
     * @dev Distribute native tokens to a single address
     */
    function distributeNative(address recipient, uint256 amount) external nonReentrant whenNotPaused onlyOwner {
        require(recipient != address(0), "UniversalDistributor: Invalid recipient");
        require(amount > 0, "UniversalDistributor: Invalid amount");
        
        payable(recipient).transfer(amount);
        emit NativeDistributed(recipient, amount);
    }
    
    /**
     * @dev Distribute ERC20 tokens to a single address
     */
    function distributeERC20(
        address token,
        address recipient,
        uint256 amount
    ) external nonReentrant whenNotPaused onlyOwner {
        require(token != address(0), "UniversalDistributor: Invalid token");
        require(recipient != address(0), "UniversalDistributor: Invalid recipient");
        require(amount > 0, "UniversalDistributor: Invalid amount");
        
        IERC20(token).transfer(recipient, amount);
        emit ERC20Distributed(token, recipient, amount);
    }
    
    /**
     * @dev Distribute native tokens to multiple addresses
     */
    function batchDistributeNative(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external nonReentrant whenNotPaused onlyOwner {
        require(recipients.length == amounts.length, "UniversalDistributor: Array length mismatch");
        require(recipients.length > 0, "UniversalDistributor: Empty arrays");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            require(recipients[i] != address(0), "UniversalDistributor: Invalid recipient");
            require(amounts[i] > 0, "UniversalDistributor: Invalid amount");
            totalAmount += amounts[i];
        }
        
        require(address(this).balance >= totalAmount, "UniversalDistributor: Insufficient balance");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            payable(recipients[i]).transfer(amounts[i]);
            emit NativeDistributed(recipients[i], amounts[i]);
        }
        
        emit BatchNativeDistributed(recipients.length, totalAmount);
    }
    
    /**
     * @dev Distribute ERC20 tokens to multiple addresses
     */
    function batchDistributeERC20(
        address token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external nonReentrant whenNotPaused onlyOwner {
        require(token != address(0), "UniversalDistributor: Invalid token");
        require(recipients.length == amounts.length, "UniversalDistributor: Array length mismatch");
        require(recipients.length > 0, "UniversalDistributor: Empty arrays");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            require(recipients[i] != address(0), "UniversalDistributor: Invalid recipient");
            require(amounts[i] > 0, "UniversalDistributor: Invalid amount");
            totalAmount += amounts[i];
        }
        
        require(IERC20(token).balanceOf(address(this)) >= totalAmount, "UniversalDistributor: Insufficient balance");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            IERC20(token).transfer(recipients[i], amounts[i]);
            emit ERC20Distributed(token, recipients[i], amounts[i]);
        }
        
        emit BatchERC20Distributed(token, recipients.length, totalAmount);
    }
    
    /**
     * @dev Rescue tokens (owner only)
     */
    function rescueTokens(address token, uint256 amount) external onlyOwner {
        require(token != address(0), "UniversalDistributor: Invalid token");
        IERC20(token).transfer(owner(), amount);
    }
    
    /**
     * @dev Fallback to receive native tokens
     */
    receive() external payable {}
}
