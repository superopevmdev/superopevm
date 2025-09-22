// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";
import {ReentrancyGuard as ReentrancyGuard} from "@superopevm/contracts/security/ReentrancyGuard.sol";

/**
 * @title CrossChainMessenger
 * @dev Cross-chain messaging contract
 */
contract CrossChainMessenger is Ownable, ReentrancyGuard {
    struct Message {
        uint256 sourceChainId;
        uint256 targetChainId;
        address sender;
        address recipient;
        bytes data;
        uint256 nonce;
        bool processed;
    }
    
    mapping(bytes32 => Message) public messages;
    mapping(uint256 => uint256) public nonces;
    mapping(address => bool) public relayers;
    
    event MessageSent(bytes32 indexed messageId, uint256 indexed targetChainId, address indexed recipient);
    event MessageReceived(bytes32 indexed messageId, uint256 indexed sourceChainId, address indexed sender);
    event RelayerAdded(address indexed relayer);
    event RelayerRemoved(address indexed relayer);
    
    function sendMessage(uint256 targetChainId, address recipient, bytes calldata data) external nonReentrant {
        require(recipient != address(0), "CrossChainMessenger: invalid recipient");
        
        uint256 nonce = nonces[targetChainId]++;
        bytes32 messageId = keccak256(abi.encodePacked(
            block.chainid, targetChainId, msg.sender, recipient, nonce, data
        ));
        
        messages[messageId] = Message({
            sourceChainId: block.chainid,
            targetChainId: targetChainId,
            sender: msg.sender,
            recipient: recipient,
            data: data,
            nonce: nonce,
            processed: false
        });
        
        emit MessageSent(messageId, targetChainId, recipient);
    }
    
    function receiveMessage(
        uint256 sourceChainId,
        address sender,
        address recipient,
        bytes calldata data,
        uint256 nonce,
        bytes32 messageId
    ) external nonReentrant {
        require(relayers[msg.sender], "CrossChainMessenger: unauthorized relayer");
        require(recipient != address(0), "CrossChainMessenger: invalid recipient");
        require(!messages[messageId].processed, "CrossChainMessenger: already processed");
        
        bytes32 expectedMessageId = keccak256(abi.encodePacked(
            sourceChainId, block.chainid, sender, recipient, nonce, data
        ));
        require(messageId == expectedMessageId, "CrossChainMessenger: invalid message");
        
        messages[messageId] = Message({
            sourceChainId: sourceChainId,
            targetChainId: block.chainid,
            sender: sender,
            recipient: recipient,
            data: data,
            nonce: nonce,
            processed: true
        });
        
        emit MessageReceived(messageId, sourceChainId, sender);
        _handleMessage(sender, recipient, data);
    }
    
    function addRelayer(address relayer) external onlyOwner {
        require(relayer != address(0), "CrossChainMessenger: invalid relayer");
        require(!relayers[relayer], "CrossChainMessenger: already added");
        relayers[relayer] = true;
        emit RelayerAdded(relayer);
    }
    
    function removeRelayer(address relayer) external onlyOwner {
        require(relayers[relayer], "CrossChainMessenger: not a relayer");
        relayers[relayer] = false;
        emit RelayerRemoved(relayer);
    }
    
    function _handleMessage(address sender, address recipient, bytes memory data) internal virtual {}
    
    function getMessage(bytes32 messageId) external view returns (
        uint256 sourceChainId,
        uint256 targetChainId,
        address sender,
        address recipient,
        bytes memory data,
        uint256 nonce,
        bool processed
    ) {
        Message storage message = messages[messageId];
        return (
            message.sourceChainId,
            message.targetChainId,
            message.sender,
            message.recipient,
            message.data,
            message.nonce,
            message.processed
        );
    }
}
