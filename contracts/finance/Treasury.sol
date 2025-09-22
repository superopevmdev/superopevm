// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ITreasury as ITreasury} from "@superopevm/contracts/finance/ITreasury.sol";
import {IERC20 as IERC20} from "@superopevm/contracts/token/ERC20/IERC20.sol";
import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";
import {Pausable as Pausable} from "@superopevm/contracts/security/Pausable.sol";
import {ReentrancyGuard as ReentrancyGuard} from "@superopevm/contracts/security/ReentrancyGuard.sol";

/**
 * @title Treasury
 * @dev Contract for managing project funds
 */
contract Treasury is ITreasury, Ownable, Pausable, ReentrancyGuard {
    // Events
    event Withdrawn(address indexed token, address indexed to, uint256 amount);
    event Deposited(address indexed token, address indexed from, uint256 amount);

    /**
     * @dev Withdraw funds from treasury
     */
    function withdraw(address token, uint256 amount) external override nonReentrant whenNotPaused onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(amount);
        } else {
            IERC20(token).transfer(owner(), amount);
        }
        emit Withdrawn(token, owner(), amount);
    }

    /**
     * @dev Deposit funds to treasury
     */
    function deposit(address token, uint256 amount) external payable override nonReentrant whenNotPaused {
        if (token == address(0)) {
            require(msg.value == amount, "Treasury: invalid native amount");
        } else {
            IERC20(token).transferFrom(msg.sender, address(this), amount);
        }
        emit Deposited(token, msg.sender, amount);
    }

    /**
     * @dev Get balance of a token
     */
    function getBalance(address token) external view override returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

    /**
     * @dev Fallback to receive native tokens
     */
    receive() external payable {}
}
