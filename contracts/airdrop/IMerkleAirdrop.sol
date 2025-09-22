// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IMerkleAirdrop
 * @dev Interface for Merkle-based airdrop contracts
 */
interface IMerkleAirdrop {
    /**
     * @dev Claim tokens from airdrop
     * @param index Leaf index
     * @param account Recipient address
     * @param amount Token amount
     * @param merkleProof Merkle proof
     */
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;

    /**
     * @dev Check if claim is valid
     * @param index Leaf index
     * @param account Recipient address
     * @param amount Token amount
     * @param merkleProof Merkle proof
     * @return True if valid
     */
    function verifyClaim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external view returns (bool);

    /**
     * @dev Check if address has claimed
     * @param account Address to check
     * @return True if claimed
     */
    function hasClaimed(address account) external view returns (bool);
}
