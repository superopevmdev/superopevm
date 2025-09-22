// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title ITreasury
 * @dev Interface for Treasury contract
 */
interface ITreasury {
    /**
     * @dev Withdraw funds from treasury
     */
    function withdraw(address token, uint256 amount) external;

    /**
     * @dev Deposit funds to treasury
     */
    function deposit(address token, uint256 amount) external payable;

    /**
     * @dev Get balance of a token
     */
    function getBalance(address token) external view returns (uint256);
}
