// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20 as IERC20} from "@superopevm/contracts/token/ERC20/IERC20.sol";
import {ERC20 as ERC20} from "@superopevm/contracts/token/ERC20/ERC20.sol";
import {ITick as ITick} from "@superopevm/contracts/token/tick/ITick.sol";
import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";
import {ReentrancyGuard as ReentrancyGuard} from "@superopevm/contracts/security/ReentrancyGuard.sol";
import {Counters as Counters} from "@superopevm/contracts/utils/math/Counters.sol";

/**
 * @title Tick
 * @dev ERC20 token with time-locking functionality
 */
contract Tick is ERC20, Ownable, ReentrancyGuard, ITick {
    using Counters for Counters.Counter;

    // Lock structure
    struct TokenLock {
        address beneficiary;
        uint256 amount;
        uint256 startTime;
        uint256 duration;
        bool claimed;
    }

    // Lock tracking
    Counters.Counter private _lockIdTracker;
    mapping(uint256 => TokenLock) public tokenLocks;
    mapping(address => uint256[]) public userLocks;

    // Events
    event TokensLocked(
        uint256 indexed lockId,
        address indexed beneficiary,
        uint256 amount,
        uint256 duration
    );
    event TokensUnlocked(uint256 indexed lockId, address indexed beneficiary, uint256 amount);

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Lock tokens for a specific duration
     */
    function lockTokens(
        address beneficiary,
        uint256 amount,
        uint256 duration
    ) external override nonReentrant returns (uint256 lockId) {
        require(beneficiary != address(0), "Tick: invalid beneficiary");
        require(amount > 0, "Tick: amount must be > 0");
        require(duration > 0, "Tick: duration must be > 0");

        // Transfer tokens from sender to this contract
        _transfer(msg.sender, address(this), amount);

        // Create new lock
        lockId = _lockIdTracker.current();
        tokenLocks[lockId] = TokenLock({
            beneficiary: beneficiary,
            amount: amount,
            startTime: block.timestamp,
            duration: duration,
            claimed: false
        });

        userLocks[beneficiary].push(lockId);
        _lockIdTracker.increment();

        emit TokensLocked(lockId, beneficiary, amount, duration);
    }

    /**
     * @dev Unlock tokens after lock period expires
     */
    function unlockTokens(uint256 lockId) external override nonReentrant {
        TokenLock storage lock = tokenLocks[lockId];
        require(lock.beneficiary == msg.sender, "Tick: not beneficiary");
        require(!lock.claimed, "Tick: tokens already claimed");
        require(block.timestamp >= lock.startTime + lock.duration, "Tick: lock not expired");

        lock.claimed = true;
        _transfer(address(this), msg.sender, lock.amount);

        emit TokensUnlocked(lockId, msg.sender, lock.amount);
    }

    /**
     * @dev Get locked token details
     */
    function getLock(uint256 lockId)
        external
        view
        override
        returns (
            address beneficiary,
            uint256 amount,
            uint256 startTime,
            uint256 duration,
            bool claimed
        )
    {
        TokenLock storage lock = tokenLocks[lockId];
        return (
            lock.beneficiary,
            lock.amount,
            lock.startTime,
            lock.duration,
            lock.claimed
        );
    }

    /**
     * @dev Get total locked tokens for an address
     */
    function getTotalLocked(address account) external view override returns (uint256) {
        uint256 totalLocked = 0;
        uint256[] storage locks = userLocks[account];

        for (uint256 i = 0; i < locks.length; i++) {
            TokenLock storage lock = tokenLocks[locks[i]];
            if (!lock.claimed) {
                totalLocked += lock.amount;
            }
        }

        return totalLocked;
    }

    /**
     * @dev Get claimable tokens for an address
     */
    function getClaimable(address account) external view override returns (uint256) {
        uint256 claimable = 0;
        uint256[] storage locks = userLocks[account];

        for (uint256 i = 0; i < locks.length; i++) {
            TokenLock storage lock = tokenLocks[locks[i]];
            if (!lock.claimed && block.timestamp >= lock.startTime + lock.duration) {
                claimable += lock.amount;
            }
        }

        return claimable;
    }

    /**
     * @dev Mint new tokens (owner only)
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Burn tokens (owner only)
     */
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}
