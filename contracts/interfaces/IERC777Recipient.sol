// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IERC777Recipient
 * @dev Interface for contracts that want to receive ERC777 tokens
 */
interface IERC777Recipient {
    /**
     * @dev Called by an ERC777 token contract whenever tokens are being moved or created
     * @param operator Address which triggered the transfer
     * @param from Token sender
     * @param to Token recipient
     * @param amount Amount of tokens
     * @param userData Additional data
     * @param operatorData Additional operator data
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}
