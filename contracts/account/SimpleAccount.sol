// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {BaseAccount as BaseAccount} from "@superopevm/contracts/account/BaseAccount.sol";
import {ECDSA as ECDSA} from "@superopevm/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title SimpleAccount
 * @dev Simple implementation of Account Abstraction (ERC-4337)
 */
contract SimpleAccount is BaseAccount {
    // Owner of the account
    address public owner;
    
    // Events
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    
    constructor(address entryPoint_, address owner_) BaseAccount(entryPoint_) {
        owner = owner_;
    }
    
    /**
     * @dev Validate signature using ECDSA
     */
    function _validateSignature(
        IUserOperation.UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal override {
        bytes32 hash = ECDSA.toEthSignedMessageHash(userOpHash);
        address recovered = ECDSA.recover(hash, userOp.signature);
        require(recovered == owner, "SimpleAccount: invalid signature");
    }
    
    /**
     * @dev Change account owner
     */
    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "SimpleAccount: invalid owner");
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }
    
    /**
     * @dev Get current owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}
