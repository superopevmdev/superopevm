// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IGovernor as IGovernor} from "@superopevm/contracts/governance/IGovernor.sol";

/**
 * @title MockGovernor
 * @dev Mock Governor contract for testing
 */
contract MockGovernor is IGovernor {
    mapping(uint256 => Proposal) public _proposals;
    uint256 public _proposalCount;

    function propose(
        address[] memory,
        uint256[] memory,
        string[] memory,
        bytes[] memory,
        string memory
    ) external returns (uint256) {
        _proposals[_proposalCount] = Proposal({
            id: _proposalCount,
            proposer: msg.sender,
            startBlock: block.number,
            endBlock: block.number + 100,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            canceled: false,
            executed: false,
            targets: new address[](0),
            values: new uint256[](0),
            signatures: new string[](0),
            calldatas: new bytes[](0),
            proposalThreshold: 0
        });
        return _proposalCount++;
    }

    function queue(uint256) external override {}

    function execute(uint256 proposalId) external payable override {
        _proposals[proposalId].executed = true;
    }

    function cancel(uint256 proposalId) external override {
        _proposals[proposalId].canceled = true;
    }

    function castVote(uint256 proposalId, uint8 support) external override {
        if (support == 1) {
            _proposals[proposalId].forVotes++;
        } else if (support == 0) {
            _proposals[proposalId].againstVotes++;
        } else {
            _proposals[proposalId].abstainVotes++;
        }
    }

    function proposals(uint256 proposalId) external view override returns (Proposal memory) {
        return _proposals[proposalId];
    }

    function state(uint256 proposalId) external view override returns (uint8) {
        if (_proposals[proposalId].canceled) return 2;
        if (_proposals[proposalId].executed) return 5;
        if (block.number < _proposals[proposalId].startBlock) return 0;
        if (block.number <= _proposals[proposalId].endBlock) return 1;
        return 4;
    }
}
