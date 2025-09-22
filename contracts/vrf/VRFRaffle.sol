// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {VRFConsumerBase as VRFConsumerBase} from "@superopevm/contracts/vrf/VRFConsumerBase.sol";
import {IERC20 as IERC20} from "@superopevm/contracts/token/ERC20/IERC20.sol";
import {Counters as Counters} from "@superopevm/contracts/utils/math/Counters.sol";

/**
 * @title VRFRaffle
 * @dev Raffle system using VRF for random winner selection
 */
contract VRFRaffle is VRFConsumerBase {
    using Counters for Counters.Counter;
    
    // Raffle structure
    struct Raffle {
        uint256 raffleId;
        uint256 requestId;
        uint256 ticketPrice;
        uint256 maxTickets;
        uint256 prizePool;
        address winner;
        uint256 winningTicket;
        uint256 endTime;
        bool completed;
        IERC20 token;
        mapping(uint256 => address) ticketOwners;
        mapping(address => uint256) ticketCounts;
    }
    
    // Raffles
    mapping(uint256 => Raffle) public raffles;
    Counters.Counter private raffleCounter;
    
    // Events
    event RaffleCreated(
        uint256 indexed raffleId,
        address indexed token,
        uint256 ticketPrice,
        uint256 maxTickets
    );
    event TicketPurchased(
        uint256 indexed raffleId,
        address indexed buyer,
        uint256 ticketCount
    );
    event RaffleCompleted(
        uint256 indexed raffleId,
        address indexed winner,
        uint256 winningTicket
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
     * @dev Create a new raffle
     */
    function createRaffle(
        address tokenAddress,
        uint256 ticketPrice,
        uint256 maxTickets,
        uint256 duration
    ) external returns (uint256) {
        uint256 raffleId = raffleCounter.current();
        Raffle storage raffle = raffles[raffleId];
        
        raffle.raffleId = raffleId;
        raffle.token = IERC20(tokenAddress);
        raffle.ticketPrice = ticketPrice;
        raffle.maxTickets = maxTickets;
        raffle.endTime = block.timestamp + duration;
        
        raffleCounter.increment();
        emit RaffleCreated(raffleId, tokenAddress, ticketPrice, maxTickets);
        
        return raffleId;
    }
    
    /**
     * @dev Purchase tickets
     */
    function purchaseTickets(uint256 raffleId, uint256 ticketCount) external {
        Raffle storage raffle = raffles[raffleId];
        require(!raffle.completed, "VRFRaffle: raffle completed");
        require(block.timestamp < raffle.endTime, "VRFRaffle: raffle ended");
        require(raffle.ticketOwners.length + ticketCount <= raffle.maxTickets, "VRFRaffle: not enough tickets");
        
        uint256 totalCost = raffle.ticketPrice * ticketCount;
        
        // Transfer tokens
        require(
            raffle.token.transferFrom(msg.sender, address(this), totalCost),
            "VRFRaffle: transfer failed"
        );
        
        // Update prize pool and ticket ownership
        raffle.prizePool += totalCost;
        raffle.ticketCounts[msg.sender] += ticketCount;
        
        for (uint256 i = 0; i < ticketCount; i++) {
            raffle.ticketOwners[raffle.ticketOwners.length] = msg.sender;
        }
        
        emit TicketPurchased(raffleId, msg.sender, ticketCount);
    }
    
    /**
     * @dev Execute raffle (request random winner)
     */
    function executeRaffle(uint256 raffleId) external returns (uint256) {
        Raffle storage raffle = raffles[raffleId];
        require(!raffle.completed, "VRFRaffle: raffle completed");
        require(block.timestamp >= raffle.endTime, "VRFRaffle: raffle not ended");
        require(raffle.ticketOwners.length > 0, "VRFRaffle: no tickets sold");
        
        uint256 requestId = super.requestRandomWords();
        raffle.requestId = requestId;
        
        return requestId;
    }
    
    /**
     * @dev Handle random words fulfillment
     */
    function _fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        require(randomWords.length == 1, "VRFRaffle: invalid word count");
        
        // Find the raffle associated with this request
        uint256 raffleId = _findRaffleByRequestId(requestId);
        Raffle storage raffle = raffles[raffleId];
        
        // Select winning ticket
        uint256 winningTicket = randomWords[0] % raffle.ticketOwners.length;
        address winner = raffle.ticketOwners[winningTicket];
        
        // Update raffle state
        raffle.winner = winner;
        raffle.winningTicket = winningTicket;
        raffle.completed = true;
        
        // Transfer prize
        require(
            raffle.token.transfer(winner, raffle.prizePool),
            "VRFRaffle: prize transfer failed"
        );
        
        emit RaffleCompleted(raffleId, winner, winningTicket);
    }
    
    /**
     * @dev Find raffle by request ID
     */
    function _findRaffleByRequestId(uint256 requestId) internal view returns (uint256) {
        for (uint256 i = 0; i < raffleCounter.current(); i++) {
            if (raffles[i].requestId == requestId) {
                return i;
            }
        }
        revert("VRFRaffle: raffle not found");
    }
    
    /**
     * @dev Get raffle details
     */
    function getRaffle(uint256 raffleId)
        external
        view
        returns (
            uint256 requestId,
            address token,
            uint256 ticketPrice,
            uint256 maxTickets,
            uint256 prizePool,
            address winner,
            uint256 winningTicket,
            uint256 endTime,
            bool completed,
            uint256 ticketsSold
        )
    {
        Raffle storage raffle = raffles[raffleId];
        return (
            raffle.requestId,
            address(raffle.token),
            raffle.ticketPrice,
            raffle.maxTickets,
            raffle.prizePool,
            raffle.winner,
            raffle.winningTicket,
            raffle.endTime,
            raffle.completed,
            raffle.ticketOwners.length
        );
    }
    
    /**
     * @dev Get ticket count for user
     */
    function getTicketCount(uint256 raffleId, address user) external view returns (uint256) {
        return raffles[raffleId].ticketCounts[user];
    }
    
    /**
     * @dev Get ticket owner
     */
    function getTicketOwner(uint256 raffleId, uint256 ticketIndex) external view returns (address) {
        return raffles[raffleId].ticketOwners[ticketIndex];
    }
}
