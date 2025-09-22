// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Pausable as Pausable} from "@superopevm/contracts/security/Pausable.sol";
import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";

/**
 * @title CircuitBreaker
 * @dev Security mechanism to pause contract operations in emergencies
 */
contract CircuitBreaker is Pausable, Ownable {
    mapping(address => bool) public protectedContracts;
    bool public emergencyMode;
    
    event ProtectionAdded(address indexed contract_);
    event ProtectionRemoved(address indexed contract_);
    event EmergencyModeActivated(bool activated);
    
    function addProtection(address contract_) external onlyOwner {
        require(contract_ != address(0), "CircuitBreaker: invalid address");
        require(!protectedContracts[contract_], "CircuitBreaker: already protected");
        protectedContracts[contract_] = true;
        emit ProtectionAdded(contract_);
    }
    
    function removeProtection(address contract_) external onlyOwner {
        require(protectedContracts[contract_], "CircuitBreaker: not protected");
        protectedContracts[contract_] = false;
        emit ProtectionRemoved(contract_);
    }
    
    function activateEmergencyMode() external onlyOwner {
        require(!emergencyMode, "CircuitBreaker: already activated");
        emergencyMode = true;
        _pause();
        emit EmergencyModeActivated(true);
    }
    
    function deactivateEmergencyMode() external onlyOwner {
        require(emergencyMode, "CircuitBreaker: not activated");
        emergencyMode = false;
        _unpause();
        emit EmergencyModeActivated(false);
    }
    
    function isProtected(address contract_) external view returns (bool) {
        return protectedContracts[contract_];
    }
    
    modifier onlyProtected() {
        require(protectedContracts[msg.sender], "CircuitBreaker: not protected");
        _;
    }
    
    modifier whenNotEmergency() {
        require(!emergencyMode, "CircuitBreaker: emergency mode");
        _;
    }
}
