// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {VRFConsumerBase as VRFConsumerBase} from "@superopevm/contracts/vrf/VRFConsumerBase.sol";

/**
 * @title VRFRandomNumber
 * @dev Simple random number consumer using VRF
 */
contract VRFRandomNumber is VRFConsumerBase {
    // Random number storage
    mapping(uint256 => uint256) public randomNumbers;
    mapping(address => uint256) public lastRequest;
    
    // Events
    event RandomNumberGenerated(
        uint256 indexed requestId,
        uint256 randomNumber,
        address indexed requester
    );
    
    constructor(
        address coordinator,
        bytes32 keyHash,
        uint64 subId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit
    ) VRFConsumerBase(
        coordinator,
        keyHash,
        subId,
        requestConfirmations,
        callbackGasLimit,
        1 // Single random word
    ) {}
    
    /**
     * @dev Request a random number
     */
    function requestRandomNumber() external returns (uint256) {
        uint256 requestId = super.requestRandomWords();
        lastRequest[msg.sender] = requestId;
        return requestId;
    }
    
    /**
     * @dev Handle random words fulfillment
     */
    function _fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        require(randomWords.length == 1, "VRFRandomNumber: invalid word count");
        
        address requester = requesters[requestId];
        uint256 randomNumber = randomWords[0];
        
        randomNumbers[requestId] = randomNumber;
        emit RandomNumberGenerated(requestId, randomNumber, requester);
    }
    
    /**
     * @dev Get random number for request
     */
    function getRandomNumber(uint256 requestId) external view returns (uint256) {
        require(fulfilled[requestId], "VRFRandomNumber: not fulfilled");
        return randomNumbers[requestId];
    }
    
    /**
     * @dev Get last request for user
     */
    function getLastRequest(address user) external view returns (uint256) {
        return lastRequest[user];
    }
}
