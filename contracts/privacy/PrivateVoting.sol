// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IZKVerifier as IZKVerifier} from "@superopevm/contracts/privacy/IZKVerifier.sol";
import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";
import {ReentrancyGuard as ReentrancyGuard} from "@superopevm/contracts/security/ReentrancyGuard.sol";
import {Counters as Counters} from "@superopevm/contracts/utils/math/Counters.sol";

/**
 * @title PrivateVoting
 * @dev Private voting system using Zero-Knowledge Proofs
 */
contract PrivateVoting is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    
    // Vote structure
    struct Vote {
        bytes32 nullifier;
        uint256 choice;
        bool valid;
    }
    
    // Poll structure
    struct Poll {
        string question;
        uint256 endTime;
        mapping(uint256 => uint256) voteCounts;
        mapping(bytes32 => bool) nullifiers;
        Counters.Counter totalVotes;
        bool finalized;
    }
    
    // ZK Verifier
    IZKVerifier public verifier;
    
    // Polls
    mapping(uint256 => Poll) public polls;
    uint256 public pollCount;
    
    // Events
    event PollCreated(uint256 indexed pollId, string question, uint256 endTime);
    event VoteCast(uint256 indexed pollId, bytes32 indexed nullifier, uint256 choice);
    event PollFinalized(uint256 indexed pollId);
    
    constructor(address verifierAddress) {
        verifier = IZKVerifier(verifierAddress);
    }
    
    /**
     * @dev Create a new poll
     */
    function createPoll(
        string memory question,
        uint256 duration
    ) external onlyOwner returns (uint256) {
        uint256 pollId = pollCount++;
        Poll storage poll = polls[pollId];
        
        poll.question = question;
        poll.endTime = block.timestamp + duration;
        
        emit PollCreated(pollId, question, poll.endTime);
        return pollId;
    }
    
    /**
     * @dev Cast a private vote
     */
    function castVote(
        uint256 pollId,
        uint256 choice,
        bytes calldata proof,
        bytes calldata publicInputs
    ) external nonReentrant {
        Poll storage poll = polls[pollId];
        require(block.timestamp <= poll.endTime, "PrivateVoting: poll ended");
        require(!poll.finalized, "PrivateVoting: poll finalized");
        
        // Verify the ZK proof
        require(verifier.verifyProof(proof, publicInputs), "PrivateVoting: invalid proof");
        
        // Extract nullifier from public inputs (first 32 bytes)
        bytes32 nullifier = bytesToBytes32(publicInputs, 0);
        
        // Check for double voting
        require(!poll.nullifiers[nullifier], "PrivateVoting: already voted");
        
        // Record the vote
        poll.nullifiers[nullifier] = true;
        poll.voteCounts[choice]++;
        poll.totalVotes.increment();
        
        emit VoteCast(pollId, nullifier, choice);
    }
    
    /**
     * @dev Finalize a poll
     */
    function finalizePoll(uint256 pollId) external onlyOwner {
        Poll storage poll = polls[pollId];
        require(block.timestamp > poll.endTime, "PrivateVoting: poll not ended");
        require(!poll.finalized, "PrivateVoting: already finalized");
        
        poll.finalized = true;
        emit PollFinalized(pollId);
    }
    
    /**
     * @dev Get vote counts for a poll
     */
    function getVoteCounts(uint256 pollId) external view returns (uint256[] memory) {
        Poll storage poll = polls[pollId];
        require(poll.finalized, "PrivateVoting: poll not finalized");
        
        // For simplicity, return counts for choices 0-2
        uint256[] memory counts = new uint256[](3);
        counts[0] = poll.voteCounts[0];
        counts[1] = poll.voteCounts[1];
        counts[2] = poll.voteCounts[2];
        
        return counts;
    }
    
    /**
     * @dev Get total votes for a poll
     */
    function getTotalVotes(uint256 pollId) external view returns (uint256) {
        return polls[pollId].totalVotes.current();
    }
    
    /**
     * @dev Convert bytes to bytes32
     */
    function bytesToBytes32(bytes memory data, uint256 offset) internal pure returns (bytes32) {
        bytes32 result;
        assembly {
            result := mload(add(data, add(offset, 0x20)))
        }
        return result;
    }
}
