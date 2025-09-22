// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IZKVerifier as IZKVerifier} from "@superopevm/contracts/privacy/IZKVerifier.sol";
import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";

/**
 * @title ZKIdentity
 * @dev Zero-Knowledge identity management system
 */
contract ZKIdentity is Ownable {
    // Identity commitment
    struct Identity {
        bytes32 commitment;
        uint256 timestamp;
        bool revoked;
    }
    
    // ZK Verifier
    IZKVerifier public verifier;
    
    // Identity registry
    mapping(address => Identity) public identities;
    mapping(bytes32 => bool) public commitmentRegistry;
    
    // Events
    event IdentityRegistered(address indexed user, bytes32 indexed commitment);
    event IdentityRevoked(address indexed user);
    event IdentityVerified(address indexed user, bool indexed result);
    
    constructor(address verifierAddress) {
        verifier = IZKVerifier(verifierAddress);
    }
    
    /**
     * @dev Register a new identity commitment
     */
    function registerIdentity(bytes32 commitment) external {
        require(commitment != bytes32(0), "ZKIdentity: invalid commitment");
        require(!commitmentRegistry[commitment], "ZKIdentity: commitment exists");
        
        identities[msg.sender] = Identity({
            commitment: commitment,
            timestamp: block.timestamp,
            revoked: false
        });
        
        commitmentRegistry[commitment] = true;
        emit IdentityRegistered(msg.sender, commitment);
    }
    
    /**
     * @dev Revoke an identity
     */
    function revokeIdentity() external {
        require(identities[msg.sender].commitment != bytes32(0), "ZKIdentity: identity not found");
        require(!identities[msg.sender].revoked, "ZKIdentity: already revoked");
        
        identities[msg.sender].revoked = true;
        emit IdentityRevoked(msg.sender);
    }
    
    /**
     * @dev Verify a proof of identity
     */
    function verifyIdentity(
        address user,
        bytes calldata proof,
        bytes calldata publicInputs
    ) external returns (bool) {
        Identity storage identity = identities[user];
        require(identity.commitment != bytes32(0), "ZKIdentity: identity not found");
        require(!identity.revoked, "ZKIdentity: identity revoked");
        
        bool result = verifier.verifyProof(proof, publicInputs);
        emit IdentityVerified(user, result);
        return result;
    }
    
    /**
     * @dev Check if an identity is valid
     */
    function isIdentityValid(address user) external view returns (bool) {
        Identity storage identity = identities[user];
        return identity.commitment != bytes32(0) && !identity.revoked;
    }
    
    /**
     * @dev Get identity information
     */
    function getIdentity(address user) external view returns (bytes32, uint256, bool) {
        Identity storage identity = identities[user];
        return (identity.commitment, identity.timestamp, identity.revoked);
    }
}
