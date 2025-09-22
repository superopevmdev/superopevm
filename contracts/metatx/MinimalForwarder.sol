// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ECDSA as ECDSA} from "@superopevm/contracts/utils/cryptography/ECDSA.sol";
import {EIP712 as EIP712} from "@superopevm/contracts/utils/cryptography/EIP712.sol";

/**
 * @title MinimalForwarder
 * @dev Minimal forwarder for meta transactions (EIP-2771)
 */
contract MinimalForwarder is EIP712 {
    // Nonce management
    mapping(address => uint256) private _nonces;
    
    // EIP-712 typehash
    bytes32 private constant _FORWARD_REQUEST_TYPEHASH = 
        keccak256(
            "ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)"
        );
    
    constructor() EIP712("MinimalForwarder", "0.0.1") {}
    
    /**
     * @dev Execute meta transaction
     */
    function execute(
        ForwardRequest calldata req,
        bytes calldata signature
    ) external payable returns (bool, bytes memory) {
        require(_nonces[req.from] == req.nonce, "MinimalForwarder: invalid nonce");
        
        // Verify signature
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _FORWARD_REQUEST_TYPEHASH,
                    req.from,
                    req.to,
                    req.value,
                    req.gas,
                    req.nonce,
                    keccak256(req.data)
                )
            )
        );
        
        address signer = ECDSA.recover(digest, signature);
        require(signer == req.from, "MinimalForwarder: invalid signature");
        
        // Increment nonce
        _nonces[req.from]++;
        
        // Execute transaction
        (bool success, bytes memory result) = req.to.call{gas: req.gas, value: req.value}(
            abi.encodePacked(req.data, req.from)
        );
        
        return (success, result);
    }
    
    /**
     * @dev Get nonce
     */
    function getNonce(address from) external view returns (uint256) {
        return _nonces[from];
    }
    
    /**
     * @dev Verify request
     */
    function verify(
        ForwardRequest calldata req,
        bytes calldata signature
    ) external view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _FORWARD_REQUEST_TYPEHASH,
                    req.from,
                    req.to,
                    req.value,
                    req.gas,
                    req.nonce,
                    keccak256(req.data)
                )
            )
        );
        
        address signer = ECDSA.recover(digest, signature);
        return signer == req.from && _nonces[req.from] == req.nonce;
    }
    
    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }
}
