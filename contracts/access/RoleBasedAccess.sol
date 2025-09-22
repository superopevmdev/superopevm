// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";

/**
 * @title RoleBasedAccess
 * @dev Advanced role-based access control system
 */
contract RoleBasedAccess is Ownable {
    struct Role {
        bytes32 name;
        mapping(address => bool) members;
        bytes32 adminRole;
        bool exists;
    }
    
    mapping(bytes32 => Role) public roles;
    
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    
    event RoleCreated(bytes32 indexed role, bytes32 indexed adminRole);
    event RoleGranted(bytes32 indexed role, address indexed account);
    event RoleRevoked(bytes32 indexed role, address indexed account);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed newAdminRole);
    
    constructor() {
        _createRole(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    function createRole(bytes32 role, bytes32 adminRole) external onlyOwner {
        require(!roles[role].exists, "RoleBasedAccess: role already exists");
        require(roles[adminRole].exists, "RoleBasedAccess: admin role doesn't exist");
        _createRole(role, adminRole);
    }
    
    function grantRole(bytes32 role, address account) external {
        require(roles[role].exists, "RoleBasedAccess: role doesn't exist");
        require(roles[roles[role].adminRole].members[msg.sender], "RoleBasedAccess: not admin");
        _grantRole(role, account);
    }
    
    function revokeRole(bytes32 role, address account) external {
        require(roles[role].exists, "RoleBasedAccess: role doesn't exist");
        require(roles[roles[role].adminRole].members[msg.sender], "RoleBasedAccess: not admin");
        _revokeRole(role, account);
    }
    
    function renounceRole(bytes32 role, address account) external {
        require(roles[role].exists, "RoleBasedAccess: role doesn't exist");
        require(account == msg.sender, "RoleBasedAccess: can only renounce for self");
        _revokeRole(role, account);
    }
    
    function hasRole(bytes32 role, address account) external view returns (bool) {
        return roles[role].members[account];
    }
    
    function getRoleAdmin(bytes32 role) external view returns (bytes32) {
        return roles[role].adminRole;
    }
    
    function _createRole(bytes32 role, bytes32 adminRole) internal {
        roles[role] = Role({
            name: role,
            adminRole: adminRole,
            exists: true
        });
        emit RoleCreated(role, adminRole);
    }
    
    function _grantRole(bytes32 role, address account) internal {
        if (!roles[role].members[account]) {
            roles[role].members[account] = true;
            emit RoleGranted(role, account);
        }
    }
    
    function _revokeRole(bytes32 role, address account) internal {
        if (roles[role].members[account]) {
            roles[role].members[account] = false;
            emit RoleRevoked(role, account);
        }
    }
    
    modifier onlyRole(bytes32 role) {
        require(roles[role].members[msg.sender], "RoleBasedAccess: missing role");
        _;
    }
}
