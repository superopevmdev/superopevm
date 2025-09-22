// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC777Recipient as IERC777Recipient} from "@superopevm/contracts/interfaces/IERC777Recipient.sol";
import {IERC777Sender as IERC777Sender} from "@superopevm/contracts/interfaces/IERC777Sender.sol";
import {IERC1155TokenReceiver as IERC1155TokenReceiver} from "@superopevm/contracts/interfaces/IERC1155TokenReceiver.sol";
import {Context as Context} from "@superopevm/contracts/utils/Context.sol";

/**
 * @title CallbackHandler
 * @dev Base contract for handling various token callbacks
 */
abstract contract CallbackHandler is 
    Context, 
    IERC777Recipient, 
    IERC777Sender, 
    IERC1155TokenReceiver 
{
    // ERC777 recipient callback
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        require(_msgSender() == operator, "CallbackHandler: Invalid operator");
        _handleTokensReceived(operator, from, to, amount, userData, operatorData);
    }

    // ERC777 sender callback
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        require(_msgSender() == operator, "CallbackHandler: Invalid operator");
        _handleTokensToSend(operator, from, to, amount, userData, operatorData);
    }

    // ERC1155 single token callback
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external override returns (bytes4) {
        require(_msgSender() == operator, "CallbackHandler: Invalid operator");
        _handleERC1155Received(operator, from, id, amount, data);
        return this.onERC1155Received.selector;
    }

    // ERC1155 batch token callback
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external override returns (bytes4) {
        require(_msgSender() == operator, "CallbackHandler: Invalid operator");
        _handleERC1155BatchReceived(operator, from, ids, amounts, data);
        return this.onERC1155BatchReceived.selector;
    }

    // Internal handlers to be implemented by derived contracts
    function _handleTokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal virtual {}

    function _handleTokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal virtual {}

    function _handleERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

    function _handleERC1155BatchReceived(
        address operator,
        address from,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}
}
