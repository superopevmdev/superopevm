// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20 as IERC20} from "@superopevm/contracts/token/ERC20/IERC20.sol";
import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";

/**
 * @title GasToken
 * @dev Gas token for gas optimization
 */
contract GasToken is IERC20, Ownable {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply;
    
    mapping(uint256 => bool) public freedTokens;
    uint256 public totalFreed;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    
    event Minted(address indexed to, uint256 amount);
    event Freed(address indexed from, uint256 amount);
    
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
        decimals = 18;
    }
    
    function mint(uint256 amount) external returns (bool) {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Minted(msg.sender, amount);
        return true;
    }
    
    function free(uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "GasToken: insufficient balance");
        
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        totalFreed += amount;
        
        for (uint256 i = 0; i < amount; i++) {
            freedTokens[totalFreed - i] = true;
        }
        
        emit Freed(msg.sender, amount);
        return true;
    }
    
    function freeUpTo(uint256 amount) external returns (uint256) {
        uint256 balance = balanceOf[msg.sender];
        if (balance > amount) {
            balance = amount;
        }
        
        if (free(balance)) {
            return balance;
        }
        return 0;
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "GasToken: invalid recipient");
        require(balanceOf[msg.sender] >= amount, "GasToken: insufficient balance");
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(to != address(0), "GasToken: invalid recipient");
        require(balanceOf[from] >= amount, "GasToken: insufficient balance");
        require(allowance[from][msg.sender] >= amount, "GasToken: insufficient allowance");
        
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }
    
    function isFreed(uint256 tokenId) external view returns (bool) {
        return freedTokens[tokenId];
    }
}
