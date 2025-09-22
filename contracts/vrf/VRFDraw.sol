// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {VRFConsumerBase as VRFConsumerBase} from "@superopevm/contracts/vrf/VRFConsumerBase.sol";
import {Counters as Counters} from "@superopevm/contracts/utils/math/Counters.sol";

/**
 * @title VRFDraw
 * @dev Random draw system using VRF
 */
contract VRFDraw is VRFConsumerBase {
    using Counters for Counters.Counter;
    
    // Draw structure
    struct Draw {
        uint256 drawId;
        uint256 requestId;
        uint256 winningNumber;
        uint256 maxNumber;
        uint256 timestamp;
        bool completed;
        address[] participants;
        mapping(address => bool) hasParticipated;
    }
    
    // Draws
    mapping(uint256 => Draw) public draws;
    Counters.Counter private drawCounter;
    
    // Events
    event DrawCreated(uint256 indexed drawId, uint256 maxNumber);
    event Participation(uint256 indexed drawId, address indexed participant);
    event DrawCompleted(uint256 indexed drawId, uint256 winningNumber);
    
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
     * @dev Create a new draw
     */
    function createDraw(uint256 maxNumber) external returns (uint256) {
        uint256 drawId = drawCounter.current();
        Draw storage draw = draws[drawId];
        
        draw.drawId = drawId;
        draw.maxNumber = maxNumber;
        draw.timestamp = block.timestamp;
        
        drawCounter.increment();
        emit DrawCreated(drawId, maxNumber);
        
        return drawId;
    }
    
    /**
     * @dev Participate in a draw
     */
    function participate(uint256 drawId) external {
        Draw storage draw = draws[drawId];
        require(!draw.completed, "VRFDraw: draw completed");
        require(!draw.hasParticipated[msg.sender], "VRFDraw: already participated");
        
        draw.participants.push(msg.sender);
        draw.hasParticipated[msg.sender] = true;
        emit Participation(drawId, msg.sender);
    }
    
    /**
     * @dev Execute draw (request random number)
     */
    function executeDraw(uint256 drawId) external returns (uint256) {
        Draw storage draw = draws[drawId];
        require(!draw.completed, "VRFDraw: draw completed");
        require(draw.participants.length > 0, "VRFDraw: no participants");
        
        uint256 requestId = super.requestRandomWords();
        draw.requestId = requestId;
        
        return requestId;
    }
    
    /**
     * @dev Handle random words fulfillment
     */
    function _fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        require(randomWords.length == 1, "VRFDraw: invalid word count");
        
        // Find the draw associated with this request
        uint256 drawId = _findDrawByRequestId(requestId);
        Draw storage draw = draws[drawId];
        
        // Calculate winning number
        uint256 winningNumber = randomWords[0] % draw.maxNumber;
        draw.winningNumber = winningNumber;
        draw.completed = true;
        
        emit DrawCompleted(drawId, winningNumber);
    }
    
    /**
     * @dev Find draw by request ID
     */
    function _findDrawByRequestId(uint256 requestId) internal view returns (uint256) {
        for (uint256 i = 0; i < drawCounter.current(); i++) {
            if (draws[i].requestId == requestId) {
                return i;
            }
        }
        revert("VRFDraw: draw not found");
    }
    
    /**
     * @dev Get draw details
     */
    function getDraw(uint256 drawId)
        external
        view
        returns (
            uint256 requestId,
            uint256 winningNumber,
            uint256 maxNumber,
            uint256 timestamp,
            bool completed,
            address[] memory participants
        )
    {
        Draw storage draw = draws[drawId];
        return (
            draw.requestId,
            draw.winningNumber,
            draw.maxNumber,
            draw.timestamp,
            draw.completed,
            draw.participants
        );
    }
    
    /**
     * @dev Check if address participated
     */
    function hasParticipated(uint256 drawId, address participant) external view returns (bool) {
        return draws[drawId].hasParticipated[participant];
    }
    
    /**
     * @dev Get participant count
     */
    function getParticipantCount(uint256 drawId) external view returns (uint256) {
        return draws[drawId].participants.length;
    }
}
