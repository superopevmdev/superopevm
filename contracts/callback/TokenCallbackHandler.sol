// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {CallbackHandler as CallbackHandler} from "@superopevm/contracts/callback/CallbackHandler.sol";
import {IERC20 as IERC20} from "@superopevm/contracts/token/ERC20/IERC20.sol";
import {IERC1155 as IERC1155} from "@superopevm/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title TokenCallbackHandler
 * @dev Enhanced callback handler with token-specific logic
 */
abstract contract TokenCallbackHandler is CallbackHandler {
    // Token approval callback
    function _handleTokenApproval(
        address token,
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {}

    // Token transfer callback
    function _handleTokenTransfer(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    // Override ERC777 handlers
    function _handleTokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal override {
        _handleTokenTransfer(_msgSender(), from, to, amount);
        super._handleTokensReceived(operator, from, to, amount, userData, operatorData);
    }

    function _handleTokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal override {
        _handleTokenTransfer(_msgSender(), from, to, amount);
        super._handleTokensToSend(operator, from, to, amount, userData, operatorData);
    }

    // Override ERC1155 handlers
    function _handleERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {
        _handleTokenTransfer(_msgSender(), from, address(this), amount);
        super._handleERC1155Received(operator, from, id, amount, data);
    }

    function _handleERC1155BatchReceived(
        address operator,
        address from,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        for (uint256 i = 0; i < ids.length; i++) {
            _handleTokenTransfer(_msgSender(), from, address(this), amounts[i]);
        }
        super._handleERC1155BatchReceived(operator, from, ids, amounts, data);
    }
}
