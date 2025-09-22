// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20 as IERC20} from "@superopevm/contracts/token/ERC20/IERC20.sol";
import {IFlashBorrower as IFlashBorrower} from "@superopevm/contracts/flashmint/IFlashBorrower.sol";
import {ReentrancyGuard as ReentrancyGuard} from "@superopevm/contracts/security/ReentrancyGuard.sol";
import {Pausable as Pausable} from "@superopevm/contracts/security/Pausable.sol";
import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";

/**
 * @title Flashmint
 * @dev Flash loan provider for ERC20 tokens with fee mechanism
 */
contract Flashmint is ReentrancyGuard, Pausable, Ownable {
    // Fee configuration (5 basis points = 0.05%)
    uint256 public constant FEE_BPS = 5;
    uint256 public constant FEE_PRECISION = 10000;
    
    // Supported tokens mapping
    mapping(address => bool) public supportedTokens;
    address[] public allSupportedTokens;
    
    // Events
    event FlashLoanInitiated(
        address indexed borrower,
        address indexed token,
        uint256 amount,
        uint256 fee,
        bytes data
    );
    
    event TokenSupported(address indexed token);
    event TokenUnsupported(address indexed token);
    
    /**
     * @dev Add a token to the supported list
     * @param token The token address to support
     */
    function addSupportedToken(address token) external onlyOwner {
        require(token != address(0), "Flashmint: Invalid token address");
        require(!supportedTokens[token], "Flashmint: Token already supported");
        
        supportedTokens[token] = true;
        allSupportedTokens.push(token);
        emit TokenSupported(token);
    }
    
    /**
     * @dev Remove a token from the supported list
     * @param token The token address to remove
     */
    function removeSupportedToken(address token) external onlyOwner {
        require(supportedTokens[token], "Flashmint: Token not supported");
        
        supportedTokens[token] = false;
        emit TokenUnsupported(token);
    }
    
    /**
     * @dev Execute a flash loan
     * @param token The token to borrow
     * @param amount The amount to borrow
     * @param data Arbitrary data for the borrower callback
     */
    function flashLoan(
        address token,
        uint256 amount,
        bytes calldata data
    ) external nonReentrant whenNotPaused {
        require(supportedTokens[token], "Flashmint: Token not supported");
        require(amount > 0, "Flashmint: Amount must be > 0");
        
        uint256 fee = calculateFee(amount);
        uint256 repaymentAmount = amount + fee;
        
        // Transfer tokens to borrower
        IERC20(token).transfer(msg.sender, amount);
        
        // Execute borrower callback
        require(
            IFlashBorrower(msg.sender).onFlashLoan(
                token,
                amount,
                fee,
                data
            ),
            "Flashmint: Callback failed"
        );
        
        // Verify repayment
        require(
            IERC20(token).balanceOf(address(this)) >= repaymentAmount,
            "Flashmint: Repayment not received"
        );
        
        emit FlashLoanInitiated(msg.sender, token, amount, fee, data);
    }
    
    /**
     * @dev Calculate flash loan fee
     * @param amount The loan amount
     * @return The fee amount
     */
    function calculateFee(uint256 amount) public pure returns (uint256) {
        return (amount * FEE_BPS) / FEE_PRECISION;
    }
    
    /**
     * @dev Withdraw accumulated fees (owner only)
     * @param token The token to withdraw
     * @param amount The amount to withdraw
     */
    function withdrawFees(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner(), amount);
    }
    
    /**
     * @dev Rescue accidentally sent tokens (owner only)
     * @param token The token to rescue
     */
    function rescueTokens(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "Flashmint: No tokens to rescue");
        
        if (!supportedTokens[token]) {
            IERC20(token).transfer(owner(), balance);
        }
    }
    
    /**
     * @dev Get all supported tokens
     * @return Array of supported token addresses
     */
    function getSupportedTokens() external view returns (address[] memory) {
        address[] memory tokens = new address[](allSupportedTokens.length);
        uint256 count = 0;
        
        for (uint256 i = 0; i < allSupportedTokens.length; i++) {
            if (supportedTokens[allSupportedTokens[i]]) {
                tokens[count] = allSupportedTokens[i];
                count++;
            }
        }
        
        // Resize array to actual count
        assembly {
            mstore(tokens, count)
        }
        
        return tokens;
    }
}
