// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20 as IERC20} from "@superopevm/contracts/token/ERC20/IERC20.sol";
import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";
import {ReentrancyGuard as ReentrancyGuard} from "@superopevm/contracts/security/ReentrancyGuard.sol";
import {SafeMath as SafeMath} from "@superopevm/contracts/utils/math/SafeMath.sol";

/**
 * @title VestingWallet
 * @dev Handles token vesting schedules
 */
contract VestingWallet is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // Vesting schedule structure
    struct VestingSchedule {
        address beneficiary;
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 cliffDuration;
        bool revocable;
        bool revoked;
    }

    // Token being vested
    IERC20 public immutable token;

    // Vesting schedules
    mapping(bytes32 => VestingSchedule) public vestingSchedules;
    mapping(address => bytes32[]) public userVestingSchedules;

    // Events
    event VestingScheduleCreated(
        bytes32 indexed scheduleId,
        address indexed beneficiary,
        uint256 totalAmount,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 cliffDuration
    );
    event TokensClaimed(bytes32 indexed scheduleId, address indexed beneficiary, uint256 amount);
    event VestingScheduleRevoked(bytes32 indexed scheduleId);

    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
    }

    /**
     * @dev Create a new vesting schedule
     */
    function createVestingSchedule(
        address beneficiary,
        uint256 totalAmount,
        uint256 startTimestamp,
        uint256 duration,
        uint256 cliffDuration,
        bool revocable
    ) external onlyOwner nonReentrant returns (bytes32 scheduleId) {
        require(beneficiary != address(0), "VestingWallet: invalid beneficiary");
        require(totalAmount > 0, "VestingWallet: amount must be > 0");
        require(duration > 0, "VestingWallet: duration must be > 0");
        require(cliffDuration <= duration, "VestingWallet: cliff exceeds duration");

        // Transfer tokens to this contract
        require(
            token.transferFrom(msg.sender, address(this), totalAmount),
            "VestingWallet: transfer failed"
        );

        // Create vesting schedule
        scheduleId = keccak256(
            abi.encodePacked(
                beneficiary,
                startTimestamp,
                totalAmount,
                block.timestamp
            )
        );

        vestingSchedules[scheduleId] = VestingSchedule({
            beneficiary: beneficiary,
            totalAmount: totalAmount,
            claimedAmount: 0,
            startTimestamp: startTimestamp,
            endTimestamp: startTimestamp + duration,
            cliffDuration: cliffDuration,
            revocable: revocable,
            revoked: false
        });

        userVestingSchedules[beneficiary].push(scheduleId);

        emit VestingScheduleCreated(
            scheduleId,
            beneficiary,
            totalAmount,
            startTimestamp,
            startTimestamp + duration,
            cliffDuration
        );
    }

    /**
     * @dev Claim vested tokens
     */
    function claim(bytes32 scheduleId) external nonReentrant {
        VestingSchedule storage schedule = vestingSchedules[scheduleId];
        require(schedule.beneficiary == msg.sender, "VestingWallet: not beneficiary");
        require(!schedule.revoked, "VestingWallet: schedule revoked");

        uint256 claimableAmount = _calculateClaimableAmount(schedule);
        require(claimableAmount > 0, "VestingWallet: nothing to claim");

        schedule.claimedAmount = schedule.claimedAmount.add(claimableAmount);
        require(
            token.transfer(msg.sender, claimableAmount),
            "VestingWallet: transfer failed"
        );

        emit TokensClaimed(scheduleId, msg.sender, claimableAmount);
    }

    /**
     * @dev Revoke vesting schedule (owner only)
     */
    function revoke(bytes32 scheduleId) external onlyOwner nonReentrant {
        VestingSchedule storage schedule = vestingSchedules[scheduleId];
        require(schedule.revocable, "VestingWallet: not revocable");
        require(!schedule.revoked, "VestingWallet: already revoked");

        uint256 unclaimedAmount = schedule.totalAmount.sub(schedule.claimedAmount);
        if (unclaimedAmount > 0) {
            require(
                token.transfer(owner(), unclaimedAmount),
                "VestingWallet: transfer failed"
            );
        }

        schedule.revoked = true;
        emit VestingScheduleRevoked(scheduleId);
    }

    /**
     * @dev Calculate claimable amount for a schedule
     */
    function _calculateClaimableAmount(VestingSchedule storage schedule)
        internal
        view
        returns (uint256)
    {
        if (block.timestamp < schedule.startTimestamp.add(schedule.cliffDuration)) {
            return 0; // Before cliff
        }

        if (block.timestamp >= schedule.endTimestamp) {
            return schedule.totalAmount.sub(schedule.claimedAmount); // Fully vested
        }

        // Linear vesting calculation
        uint256 timePassed = block.timestamp.sub(schedule.startTimestamp);
        uint256 totalDuration = schedule.endTimestamp.sub(schedule.startTimestamp);
        uint256 vestedAmount = schedule.totalAmount.mul(timePassed).div(totalDuration);

        return vestedAmount.sub(schedule.claimedAmount);
    }

    /**
     * @dev Get vesting schedule details
     */
    function getVestingSchedule(bytes32 scheduleId)
        external
        view
        returns (
            address beneficiary,
            uint256 totalAmount,
            uint256 claimedAmount,
            uint256 startTimestamp,
            uint256 endTimestamp,
            uint256 cliffDuration,
            bool revocable,
            bool revoked
        )
    {
        VestingSchedule storage schedule = vestingSchedules[scheduleId];
        return (
            schedule.beneficiary,
            schedule.totalAmount,
            schedule.claimedAmount,
            schedule.startTimestamp,
            schedule.endTimestamp,
            schedule.cliffDuration,
            schedule.revocable,
            schedule.revoked
        );
    }

    /**
     * @dev Get claimable amount for a schedule
     */
    function getClaimableAmount(bytes32 scheduleId) external view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[scheduleId];
        return _calculateClaimableAmount(schedule);
    }

    /**
     * @dev Get all vesting schedules for a user
     */
    function getUserVestingSchedules(address user)
        external
        view
        returns (bytes32[] memory)
    {
        return userVestingSchedules[user];
    }
}
