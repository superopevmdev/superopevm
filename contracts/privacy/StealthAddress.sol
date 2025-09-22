// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable as Ownable} from "@superopevm/contracts/access/Ownable.sol";
import {ECDSA as ECDSA} from "@superopevm/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title StealthAddress
 * @dev Stealth address generation for private transactions
 */
contract StealthAddress is Ownable {
    // Stealth meta-address structure
    struct StealthMetaAddress {
        address spendingPublicKey;
        uint256 viewingPublicKey;
    }
    
    // Stealth address registry
    mapping(address => StealthMetaAddress) public stealthMetaAddresses;
    mapping(address => address) public stealthAddresses;
    
    // Events
    event StealthMetaAddressRegistered(address indexed user, address spendingKey, uint256 viewingKey);
    event StealthAddressGenerated(address indexed stealthAddress, address indexed user);
    
    /**
     * @dev Register a stealth meta-address
     */
    function registerStealthMetaAddress(
        address spendingPublicKey,
        uint256 viewingPublicKey
    ) external {
        require(spendingPublicKey != address(0), "StealthAddress: invalid spending key");
        
        stealthMetaAddresses[msg.sender] = StealthMetaAddress({
            spendingPublicKey: spendingPublicKey,
            viewingPublicKey: viewingPublicKey
        });
        
        emit StealthMetaAddressRegistered(msg.sender, spendingPublicKey, viewingPublicKey);
    }
    
    /**
     * @dev Generate a stealth address
     */
    function generateStealthAddress(
        address recipient,
        uint256 ephemeralKey
    ) external returns (address) {
        StealthMetaAddress memory meta = stealthMetaAddresses[recipient];
        require(meta.spendingPublicKey != address(0), "StealthAddress: recipient not registered");
        
        // Generate shared secret
        uint256 sharedSecret = uint256(
            keccak256(abi.encodePacked(ephemeralKey, meta.viewingPublicKey))
        );
        
        // Generate stealth address
        address stealthAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            meta.spendingPublicKey,
                            sharedSecret
                        )
                    )
                )
            )
        );
        
        stealthAddresses[stealthAddress] = recipient;
        emit StealthAddressGenerated(stealthAddress, recipient);
        
        return stealthAddress;
    }
    
    /**
     * @dev Check if an address is a stealth address
     */
    function isStealthAddress(address addr) external view returns (bool) {
        return stealthAddresses[addr] != address(0);
    }
    
    /**
     * @dev Get the owner of a stealth address
     */
    function getStealthAddressOwner(address addr) external view returns (address) {
        return stealthAddresses[addr];
    }
}
