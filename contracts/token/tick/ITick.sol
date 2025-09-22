// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title ITick
 * @dev Interface for Tick token with time-locking functionality
 */
interface ITick {
    /**
     * @dev Lock tokens for a specific duration
     */
    function lockTokens(
        address beneficiary,
        uint256 amount,
        uint256 duration
    ) external returns (uint256 lockId);

    /**
     * @dev Unlock tokens after lock period expires
     */
    function unlockTokens(uint256 lockId) external;

    /**
     * @dev Get locked token details
     */
    function getLock(uint256 lockId)
        external
        view
        returns (
            address beneficiary,
            uint256 amount,
            uint256 startTime,
            uint256 duration,
            bool claimed
        );

    /**
     * @dev Get total locked tokens for an address
     */
    function getTotalLocked(address account) external view returns (uint256);

    /**
     * @dev Get claimable tokens for an address
     */
    function getClaimable(address account) external view returns (uint256);
}
