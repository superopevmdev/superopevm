// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";
import {Pausable as Pausable} from "@superopevm/contracts/security/Pausable.sol";
import {ReentrancyGuard as ReentrancyGuard} from "@superopevm/contracts/security/ReentrancyGuard.sol";

/**
 * @title NativeDistributor
 * @dev Distribute native tokens (ETH) to multiple addresses
 */
contract NativeDistributor is Ownable, Pausable, ReentrancyGuard {
    // Events
    event Distributed(address indexed recipient, uint256 amount);
    event BatchDistributed(uint256 totalRecipients, uint256 totalAmount);
    
    /**
     * @dev Distribute native tokens to a single address
     */
    function distribute(address recipient, uint256 amount) external nonReentrant whenNotPaused onlyOwner {
        require(recipient != address(0), "NativeDistributor: Invalid recipient");
        require(amount > 0, "NativeDistributor: Invalid amount");
        
        payable(recipient).transfer(amount);
        emit Distributed(recipient, amount);
    }
    
    /**
     * @dev Distribute native tokens to multiple addresses
     */
    function batchDistribute(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external nonReentrant whenNotPaused onlyOwner {
        require(recipients.length == amounts.length, "NativeDistributor: Array length mismatch");
        require(recipients.length > 0, "NativeDistributor: Empty arrays");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            require(recipients[i] != address(0), "NativeDistributor: Invalid recipient");
            require(amounts[i] > 0, "NativeDistributor: Invalid amount");
            totalAmount += amounts[i];
        }
        
        require(address(this).balance >= totalAmount, "NativeDistributor: Insufficient balance");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            payable(recipients[i]).transfer(amounts[i]);
            emit Distributed(recipients[i], amounts[i]);
        }
        
        emit BatchDistributed(recipients.length, totalAmount);
    }
    
    /**
     * @dev Fallback to receive native tokens
     */
    receive() external payable {}
}
