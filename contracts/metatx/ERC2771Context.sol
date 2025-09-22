// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Context as Context} from "@superopevm/contracts/utils/Context.sol";

/**
 * @title ERC2771Context
 * @dev Context variant with ERC-2771 support
 */
abstract contract ERC2771Context is Context {
    // Trusted forwarder
    address private _trustedForwarder;
    
    event TrustedForwarderChanged(address indexed oldForwarder, address indexed newForwarder);
    
    constructor(address trustedForwarder_) {
        _trustedForwarder = trustedForwarder_;
    }
    
    /**
     * @dev Check if sender is trusted forwarder
     */
    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == _trustedForwarder;
    }
    
    /**
     * @dev Get trusted forwarder
     */
    function getTrustedForwarder() external view returns (address) {
        return _trustedForwarder;
    }
    
    /**
     * @dev Set trusted forwarder
     */
    function setTrustedForwarder(address trustedForwarder_) external {
        require(trustedForwarder_ != address(0), "ERC2771Context: invalid forwarder");
        emit TrustedForwarderChanged(_trustedForwarder, trustedForwarder_);
        _trustedForwarder = trustedForwarder_;
    }
    
    /**
     * @dev Extract sender from context
     */
    function _msgSender() internal view virtual override returns (address sender) {
        if (msg.sender == _trustedForwarder) {
            // Extract sender from calldata
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }
    
    /**
     * @dev Extract data from context
     */
    function _msgData() internal view virtual override returns (bytes calldata) {
        if (msg.sender == _trustedForwarder) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}
