// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IERC1155TokenReceiver
 * @dev Interface for contracts that want to receive ERC1155 tokens
 */
interface IERC1155TokenReceiver {
    /**
     * @dev Handle the receipt of a single ERC1155 token type
     * @param operator Address which triggered the transfer
     * @param from Token sender
     * @param id Token ID
     * @param amount Token amount
     * @param data Additional data
     * @return bytes4 `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handle the receipt of multiple ERC1155 token types
     * @param operator Address which triggered the transfer
     * @param from Token sender
     * @param ids Array of token IDs
     * @param amounts Array of token amounts
     * @param data Additional data
     * @return bytes4 `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4);
}
