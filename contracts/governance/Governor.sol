// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IGovernor as IGovernor} from "@superopevm/contracts/governance/IGovernor.sol";
import {IERC20 as IERC20} from "@superopevm/contracts/token/ERC20/IERC20.sol";
import {SafeMath as SafeMath} from "@superopevm/contracts/utils/math/SafeMath.sol";
import {Counters as Counters} from "@superopevm/contracts/utils/math/Counters.sol";
import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";
import {Pausable as Pausable} from "@superopevm/contracts/security/Pausable.sol";

/**
 * @title Governor
 * @dev Governance contract for proposing and voting on proposals
 */
contract Governor is IGovernor, Ownable, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // Governance token
    IERC20 public token;

    // Voting settings
    uint256 public votingPeriod;
    uint256 public votingDelay;
    uint256 public proposalThreshold;

    // Proposal tracking
    Counters.Counter private _proposalIdTracker;
    mapping(uint256 => Proposal) public proposals;

    // Vote tracking
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Events
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer);
    event VoteCast(address indexed voter, uint256 indexed proposalId, uint8 support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);

    constructor(
        address token_,
        uint256 votingPeriod_,
        uint256 votingDelay_,
        uint256 proposalThreshold_
    ) {
        token = IERC20(token_);
        votingPeriod = votingPeriod_;
        votingDelay = votingDelay_;
        proposalThreshold = proposalThreshold_;
    }

    /**
     * @dev Create a new proposal
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external whenNotPaused returns (uint256) {
        require(
            token.balanceOf(msg.sender) >= proposalThreshold,
            "Governor: proposer votes below threshold"
        );

        uint256 proposalId = _proposalIdTracker.current();
        _proposalIdTracker.increment();

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            startBlock: block.number.add(votingDelay),
            endBlock: block.number.add(votingDelay).add(votingPeriod),
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            canceled: false,
            executed: false,
            targets: targets,
            values: values,
            signatures: signatures,
            calldatas: calldatas,
            proposalThreshold: proposalThreshold
        });

        emit ProposalCreated(proposalId, msg.sender);
        return proposalId;
    }

    /**
     * @dev Queue a proposal for execution
     */
    function queue(uint256 proposalId) external override whenNotPaused {
        require(state(proposalId) == 4, "Governor: proposal not successful");
        Proposal storage proposal = proposals[proposalId];

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            // Queue logic would go here
        }
    }

    /**
     * @dev Execute a proposal
     */
    function execute(uint256 proposalId) external payable override whenNotPaused {
        require(state(proposalId) == 5, "Governor: proposal not ready for execution");
        Proposal storage proposal = proposals[proposalId];

        proposal.executed = true;
        emit ProposalExecuted(proposalId);

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            (bool success, ) = proposal.targets[i].call{value: proposal.values[i]}(
                abi.encodePacked(
                    bytes4(keccak256(bytes(proposal.signatures[i]))),
                    proposal.calldatas[i]
                )
            );
            require(success, "Governor: proposal execution failed");
        }
    }

    /**
     * @dev Cancel a proposal
     */
    function cancel(uint256 proposalId) external override {
        Proposal storage proposal = proposals[proposalId];
        require(
            msg.sender == proposal.proposer ||
            token.balanceOf(proposal.proposer) < proposal.proposalThreshold,
            "Governor: cannot cancel"
        );

        proposal.canceled = true;
        emit ProposalCanceled(proposalId);
    }

    /**
     * @dev Cast vote on a proposal
     */
    function castVote(uint256 proposalId, uint8 support) external override whenNotPaused {
        require(state(proposalId) == 1, "Governor: voting not active");
        require(!hasVoted[proposalId][msg.sender], "Governor: already voted");

        uint256 votes = token.balanceOf(msg.sender);
        hasVoted[proposalId][msg.sender] = true;

        if (support == 1) {
            proposals[proposalId].forVotes = proposals[proposalId].forVotes.add(votes);
        } else if (support == 0) {
            proposals[proposalId].againstVotes = proposals[proposalId].againstVotes.add(votes);
        } else if (support == 2) {
            proposals[proposalId].abstainVotes = proposals[proposalId].abstainVotes.add(votes);
        }

        emit VoteCast(msg.sender, proposalId, support);
    }

    /**
     * @dev Get proposal state
     */
    function state(uint256 proposalId) public view override returns (uint8) {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.canceled) {
            return 2; // Canceled
        } else if (block.number <= proposal.startBlock) {
            return 0; // Pending
        } else if (block.number <= proposal.endBlock) {
            return 1; // Active
        } else if (proposal.forVotes > proposal.againstVotes) {
            return 4; // Succeeded
        } else {
            return 3; // Defeated
        }
    }

    /**
     * @dev Update voting settings (owner only)
     */
    function setVotingSettings(
        uint256 newVotingPeriod,
        uint256 newVotingDelay,
        uint256 newProposalThreshold
    ) external onlyOwner {
        votingPeriod = newVotingPeriod;
        votingDelay = newVotingDelay;
        proposalThreshold = newProposalThreshold;
    }
}
