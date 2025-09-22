// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {CallbackRegistry as CallbackRegistry} from "@superopevm/contracts/callback/CallbackRegistry.sol";
import {IERC777Recipient as IERC777Recipient} from "@superopevm/contracts/interfaces/IERC777Recipient.sol";
import {IERC777Sender as IERC777Sender} from "@superopevm/contracts/interfaces/IERC777Sender.sol";
import {IERC1155TokenReceiver as IERC1155TokenReceiver} from "@superopevm/contracts/interfaces/IERC1155TokenReceiver.sol";

/**
 * @title CallbackProxy
 * @dev Proxy contract to forward callbacks to registered handlers
 */
contract CallbackProxy is 
    IERC777Recipient, 
    IERC777Sender, 
    IERC1155TokenReceiver 
{
    CallbackRegistry public registry;
    
    event CallbackForwarded(address indexed handler, bytes4 indexed functionSignature);
    
    constructor(address registryAddress) {
        registry = CallbackRegistry(registryAddress);
    }
    
    // ERC777 recipient callback
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        _forwardCallback(
            abi.encodeWithSelector(
                IERC777Recipient.tokensReceived.selector,
                operator,
                from,
                to,
                amount,
                userData,
                operatorData
            )
        );
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
        _forwardCallback(
            abi.encodeWithSelector(
                IERC777Sender.tokensToSend.selector,
                operator,
                from,
                to,
                amount,
                userData,
                operatorData
            )
        );
    }

    // ERC1155 single token callback
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external override returns (bytes4) {
        bytes memory result = _forwardCallbackWithReturn(
            abi.encodeWithSelector(
                IERC1155TokenReceiver.onERC1155Received.selector,
                operator,
                from,
                id,
                amount,
                data
            )
        );
        
        return abi.decode(result, (bytes4));
    }

    // ERC1155 batch token callback
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external override returns (bytes4) {
        bytes memory result = _forwardCallbackWithReturn(
            abi.encodeWithSelector(
                IERC1155TokenReceiver.onERC1155BatchReceived.selector,
                operator,
                from,
                ids,
                amounts,
                data
            )
        );
        
        return abi.decode(result, (bytes4));
    }
    
    /**
     * @dev Forward callback to all registered handlers
     */
    function _forwardCallback(bytes memory data) internal {
        address[] memory handlers = registry.getAllHandlers();
        
        for (uint256 i = 0; i < handlers.length; i++) {
            (bool success, ) = handlers[i].call(data);
            if (success) {
                emit CallbackForwarded(handlers[i], bytes4(data[:4]));
            }
        }
    }
    
    /**
     * @dev Forward callback with return value
     */
    function _forwardCallbackWithReturn(bytes memory data) internal returns (bytes memory) {
        address[] memory handlers = registry.getAllHandlers();
        
        for (uint256 i = 0; i < handlers.length; i++) {
            (bool success, bytes memory result) = handlers[i].call(data);
            if (success) {
                emit CallbackForwarded(handlers[i], bytes4(data[:4]));
                return result;
            }
        }
        
        revert("CallbackProxy: No handler responded");
    }
}
