// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";

/**
 * @title CallbackRegistry
 * @dev Registry for managing callback handlers
 */
contract CallbackRegistry is Ownable {
    mapping(address => bool) public registeredHandlers;
    address[] public allHandlers;
    
    event HandlerRegistered(address indexed handler);
    event HandlerUnregistered(address indexed handler);
    
    /**
     * @dev Register a callback handler
     */
    function registerHandler(address handler) external onlyOwner {
        require(handler != address(0), "CallbackRegistry: Invalid handler");
        require(!registeredHandlers[handler], "CallbackRegistry: Already registered");
        
        registeredHandlers[handler] = true;
        allHandlers.push(handler);
        emit HandlerRegistered(handler);
    }
    
    /**
     * @dev Unregister a callback handler
     */
    function unregisterHandler(address handler) external onlyOwner {
        require(registeredHandlers[handler], "CallbackRegistry: Not registered");
        
        registeredHandlers[handler] = false;
        emit HandlerUnregistered(handler);
    }
    
    /**
     * @dev Check if a handler is registered
     */
    function isHandlerRegistered(address handler) external view returns (bool) {
        return registeredHandlers[handler];
    }
    
    /**
     * @dev Get all registered handlers
     */
    function getAllHandlers() external view returns (address[] memory) {
        address[] memory handlers = new address[](allHandlers.length);
        uint256 count = 0;
        
        for (uint256 i = 0; i < allHandlers.length; i++) {
            if (registeredHandlers[allHandlers[i]]) {
                handlers[count] = allHandlers[i];
                count++;
            }
        }
        
        // Resize array to actual count
        assembly {
            mstore(handlers, count)
        }
        
        return handlers;
    }
}
