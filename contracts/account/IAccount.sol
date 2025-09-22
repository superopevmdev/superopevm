// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IUserOperation as IUserOperation} from "@superopevm/contracts/account/IUserOperation.sol";

/**
 * @title IAccount
 * @dev Interface for Account Abstraction (ERC-4337)
 */
interface IAccount {
    /**
     * @dev Validate user operation and pay fee
     */
    function validateUserOp(
        IUserOperation.UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external returns (uint256 validationData);
    
    /**
     * @dev Get account nonce
     */
    function getNonce() external view returns (uint256);
}
