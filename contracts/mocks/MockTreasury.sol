// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ITreasury as ITreasury} from "@superopevm/contracts/finance/ITreasury.sol";

/**
 * @title MockTreasury
 * @dev Mock Treasury contract for testing
 */
contract MockTreasury is ITreasury {
    mapping(address => uint256) public _balances;

    function withdraw(address token, uint256 amount) external override {
        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            _balances[token] -= amount;
        }
    }

    function deposit(address token, uint256 amount) external payable override {
        if (token == address(0)) {
            require(msg.value == amount, "MockTreasury: invalid native amount");
        } else {
            _balances[token] += amount;
        }
    }

    function getBalance(address token) external view override returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else {
            return _balances[token];
        }
    }

    receive() external payable {}
}
