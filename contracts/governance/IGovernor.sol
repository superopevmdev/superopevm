// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IGovernor
 * @dev Interface for Governor contract
 */
interface IGovernor {
    /**
     * @dev Proposal structure
     */
    struct Proposal {
        uint256 id;
        address proposer;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bool canceled;
        bool executed;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 proposalThreshold;
    }

    /**
     * @dev Queue a proposal for execution
     */
    function queue(uint256 proposalId) external;

    /**
     * @dev Execute a proposal
     */
    function execute(uint256 proposalId) external payable;

    /**
     * @dev Cancel a proposal
     */
    function cancel(uint256 proposalId) external;

    /**
     * @dev Cast vote on a proposal
     */
    function castVote(uint256 proposalId, uint8 support) external;

    /**
     * @dev Get proposal details
     */
    function proposals(uint256 proposalId) external view returns (Proposal memory);

    /**
     * @dev Check if proposal has passed
     */
    function state(uint256 proposalId) external view returns (uint8);
}
