// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20 as IERC20} from "@superopevm/contracts/token/ERC20/IERC20.sol";
import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";
import {Pausable as Pausable} from "@superopevm/contracts/security/Pausable.sol";
import {ReentrancyGuard as ReentrancyGuard} from "@superopevm/contracts/security/ReentrancyGuard.sol";

/**
 * @title ERC20Distributor
 * @dev Distribute ERC20 tokens to multiple addresses
 */
contract ERC20Distributor is Ownable, Pausable, ReentrancyGuard {
    // Events
    event Distributed(address indexed token, address indexed recipient, uint256 amount);
    event BatchDistributed(address indexed token, uint256 totalRecipients, uint256 totalAmount);
    
    /**
     * @dev Distribute ERC20 tokens to a single address
     */
    function distribute(
        address token,
        address recipient,
        uint256 amount
    ) external nonReentrant whenNotPaused onlyOwner {
        require(token != address(0), "ERC20Distributor: Invalid token");
        require(recipient != address(0), "ERC20Distributor: Invalid recipient");
        require(amount > 0, "ERC20Distributor: Invalid amount");
        
        IERC20(token).transfer(recipient, amount);
        emit Distributed(token, recipient, amount);
    }
    
    /**
     * @dev Distribute ERC20 tokens to multiple addresses
     */
    function batchDistribute(
        address token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external nonReentrant whenNotPaused onlyOwner {
        require(token != address(0), "ERC20Distributor: Invalid token");
        require(recipients.length == amounts.length, "ERC20Distributor: Array length mismatch");
        require(recipients.length > 0, "ERC20Distributor: Empty arrays");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            require(recipients[i] != address(0), "ERC20Distributor: Invalid recipient");
            require(amounts[i] > 0, "ERC20Distributor: Invalid amount");
            totalAmount += amounts[i];
        }
        
        require(IERC20(token).balanceOf(address(this)) >= totalAmount, "ERC20Distributor: Insufficient balance");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            IERC20(token).transfer(recipients[i], amounts[i]);
            emit Distributed(token, recipients[i], amounts[i]);
        }
        
        emit BatchDistributed(token, recipients.length, totalAmount);
    }
    
    /**
     * @dev Rescue tokens (owner only)
     */
    function rescueTokens(address token, uint256 amount) external onlyOwner {
        require(token != address(0), "ERC20Distributor: Invalid token");
        IERC20(token).transfer(owner(), amount);
    }
}
