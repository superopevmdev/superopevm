// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IVRFCoordinator as IVRFCoordinator} from "@superopevm/contracts/vrf/IVRFCoordinator.sol";
import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";

/**
 * @title VRFConsumerBase
 * @dev Base contract for VRF consumers
 */
abstract contract VRFConsumerBase is Ownable {
    // VRF Coordinator
    IVRFCoordinator public immutable COORDINATOR;
    
    // Key Hash
    bytes32 public immutable KEY_HASH;
    
    // Subscription ID
    uint64 public immutable SUBSCRIPTION_ID;
    
    // Request confirmations
    uint16 public immutable REQUEST_CONFIRMATIONS;
    
    // Callback gas limit
    uint32 public immutable CALLBACK_GAS_LIMIT;
    
    // Number of words requested
    uint32 public immutable NUM_WORDS;
    
    // Request tracking
    mapping(uint256 => address) public requesters;
    mapping(uint256 => bool) public fulfilled;
    
    // Events
    event RandomWordsRequested(
        uint256 indexed requestId,
        address indexed requester,
        uint32 numWords
    );
    event RandomWordsFulfilled(
        uint256 indexed requestId,
        uint256[] randomWords
    );
    
    constructor(
        address coordinator,
        bytes32 keyHash,
        uint64 subId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) {
        COORDINATOR = IVRFCoordinator(coordinator);
        KEY_HASH = keyHash;
        SUBSCRIPTION_ID = subId;
        REQUEST_CONFIRMATIONS = requestConfirmations;
        CALLBACK_GAS_LIMIT = callbackGasLimit;
        NUM_WORDS = numWords;
    }
    
    /**
     * @dev Request random words
     */
    function requestRandomWords() external returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            KEY_HASH,
            SUBSCRIPTION_ID,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );
        
        requesters[requestId] = msg.sender;
        emit RandomWordsRequested(requestId, msg.sender, NUM_WORDS);
    }
    
    /**
     * @dev Callback function for VRF
     */
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal {
        require(msg.sender == address(COORDINATOR), "VRFConsumerBase: invalid caller");
        require(!fulfilled[requestId], "VRFConsumerBase: already fulfilled");
        
        fulfilled[requestId] = true;
        emit RandomWordsFulfilled(requestId, randomWords);
        
        _fulfillRandomWords(requestId, randomWords);
    }
    
    /**
     * @dev Handle random words fulfillment (to be implemented)
     */
    function _fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal virtual;
    
    /**
     * @dev Check if request is fulfilled
     */
    function isRequestFulfilled(uint256 requestId) external view returns (bool) {
        return fulfilled[requestId];
    }
    
    /**
     * @dev Get requester for a request
     */
    function getRequester(uint256 requestId) external view returns (address) {
        return requesters[requestId];
    }
}
