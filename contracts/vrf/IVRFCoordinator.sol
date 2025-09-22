// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IVRFCoordinator
 * @dev Interface for Chainlink VRF Coordinator
 */
interface IVRFCoordinator {
    /**
     * @dev Request random words
     */
    function requestRandomWords(
        bytes32 keyHash,
        uint64 s_subscriptionId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);

    /**
     * @dev Get subscription details
     */
    function getSubscription(uint64 subId)
        external
        view
        returns (
            uint96 balance,
            uint64 reqCount,
            address owner,
            address[] memory consumers
        );

    /**
     * @dev Create a new subscription
     */
    function createSubscription() external returns (uint64 subId);

    /**
     * @dev Add consumer to subscription
     */
    function addConsumer(uint64 subId, address consumer) external;

    /**
     * @dev Remove consumer from subscription
     */
    function removeConsumer(uint64 subId, address consumer) external;

    /**
     * @dev Cancel subscription
     */
    function cancelSubscription(uint64 subId, address to) external;

    /**
     * @dev Request subscription owner transfer
     */
    function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

    /**
     * @dev Accept subscription owner transfer
     */
    function acceptSubscriptionOwnerTransfer(uint64 subId) external;

    /**
     * @dev Get subscription consumer list
     */
    function consumers(uint64 subId, uint256 index) external view returns (address);
}
