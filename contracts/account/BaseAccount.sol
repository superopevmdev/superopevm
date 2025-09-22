// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IAccount as IAccount} from "@superopevm/contracts/account/IAccount.sol";
import {IUserOperation as IUserOperation} from "@superopevm/contracts/account/IUserOperation.sol";
import {ECDSA as ECDSA} from "@superopevm/contracts/utils/cryptography/ECDSA.sol";
import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";

/**
 * @title BaseAccount
 * @dev Base implementation for Account Abstraction (ERC-4337)
 */
abstract contract BaseAccount is IAccount, Ownable {
    // Nonce management
    uint256 public nonce;
    
    // Entrypoint address
    address public immutable entryPoint;
    
    // Events
    event UserOperationExecuted(address indexed sender, bool success);
    
    constructor(address entryPoint_) {
        entryPoint = entryPoint_;
    }
    
    /**
     * @dev Validate user operation
     */
    function validateUserOp(
        IUserOperation.UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external override returns (uint256 validationData) {
        require(msg.sender == entryPoint, "BaseAccount: invalid entryPoint");
        
        // Validate signature
        _validateSignature(userOp, userOpHash);
        
        // Pay prefund if needed
        if (missingAccountFunds > 0) {
            payable(entryPoint).call{value: missingAccountFunds}("");
        }
        
        return 0; // Valid signature
    }
    
    /**
     * @dev Execute user operation
     */
    function executeUserOp(
        address dest,
        uint256 value,
        bytes calldata func
    ) external {
        require(msg.sender == entryPoint, "BaseAccount: invalid entryPoint");
        
        (bool success, ) = dest.call{value: value}(func);
        emit UserOperationExecuted(dest, success);
    }
    
    /**
     * @dev Get account nonce
     */
    function getNonce() external view override returns (uint256) {
        return nonce;
    }
    
    /**
     * @dev Increment nonce
     */
    function incrementNonce() external {
        require(msg.sender == entryPoint, "BaseAccount: invalid entryPoint");
        nonce++;
    }
    
    /**
     * @dev Validate signature (to be implemented by derived contracts)
     */
    function _validateSignature(
        IUserOperation.UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual;
}
