// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";

/**
 * @title RateLimiter
 * @dev Rate limiting mechanism for contract operations
 */
contract RateLimiter is Ownable {
    struct RateLimit {
        uint256 lastActionTime;
        uint256 actionCount;
        uint256 windowSize;
        uint256 maxActions;
    }
    
    mapping(address => RateLimit) public rateLimits;
    mapping(address => bool) public exemptAddresses;
    
    event RateLimitSet(address indexed account, uint256 windowSize, uint256 maxActions);
    event ExemptionAdded(address indexed account);
    event ExemptionRemoved(address indexed account);
    
    function setRateLimit(
        address account,
        uint256 windowSize,
        uint256 maxActions
    ) external onlyOwner {
        require(account != address(0), "RateLimiter: invalid address");
        require(windowSize > 0, "RateLimiter: window size must be > 0");
        require(maxActions > 0, "RateLimiter: max actions must be > 0");
        
        rateLimits[account] = RateLimit({
            lastActionTime: block.timestamp,
            actionCount: 0,
            windowSize: windowSize,
            maxActions: maxActions
        });
        
        emit RateLimitSet(account, windowSize, maxActions);
    }
    
    function addExemption(address account) external onlyOwner {
        require(account != address(0), "RateLimiter: invalid address");
        require(!exemptAddresses[account], "RateLimiter: already exempt");
        
        exemptAddresses[account] = true;
        emit ExemptionAdded(account);
    }
    
    function removeExemption(address account) external onlyOwner {
        require(exemptAddresses[account], "RateLimiter: not exempt");
        
        exemptAddresses[account] = false;
        emit ExemptionRemoved(account);
    }
    
    function checkRateLimit(address account) external returns (bool) {
        if (exemptAddresses[account]) {
            return true;
        }
        
        RateLimit storage limit = rateLimits[account];
        if (limit.windowSize == 0) {
            return true;
        }
        
        if (block.timestamp > limit.lastActionTime + limit.windowSize) {
            limit.actionCount = 0;
            limit.lastActionTime = block.timestamp;
        }
        
        require(limit.actionCount < limit.maxActions, "RateLimiter: rate limit exceeded");
        limit.actionCount++;
        
        return true;
    }
    
    function getRemainingActions(address account) external view returns (uint256) {
        if (exemptAddresses[account]) {
            return type(uint256).max;
        }
        
        RateLimit storage limit = rateLimits[account];
        if (limit.windowSize == 0) {
            return type(uint256).max;
        }
        
        if (block.timestamp > limit.lastActionTime + limit.windowSize) {
            return limit.maxActions;
        }
        
        return limit.maxActions - limit.actionCount;
    }
    
    function getTimeUntilReset(address account) external view returns (uint256) {
        if (exemptAddresses[account]) {
            return 0;
        }
        
        RateLimit storage limit = rateLimits[account];
        if (limit.windowSize == 0) {
            return 0;
        }
        
        uint256 resetTime = limit.lastActionTime + limit.windowSize;
        if (block.timestamp >= resetTime) {
            return 0;
        }
        
        return resetTime - block.timestamp;
    }
    
    modifier rateLimited(address account) {
        require(checkRateLimit(account), "RateLimiter: rate limit exceeded");
        _;
    }
}
