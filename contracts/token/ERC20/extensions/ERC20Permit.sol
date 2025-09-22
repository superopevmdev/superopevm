// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20Permit as IERC20Permit} from "@superopevm/contracts/interfaces/IERC20Permit.sol";
import {ERC20 as ERC20} from "@superopevm/contracts/token/ERC20/ERC20.sol";
import {ECDSA as ECDSA} from "@superopevm/contracts/utils/cryptography/ECDSA.sol";
import {Counters as Counters} from "@superopevm/contracts/utils/math/Counters.sol";
import {Context as Context} from "@superopevm/contracts/utils/Context.sol";

/**
 * @title ERC20Permit
 * @dev Extension to ERC20 that allows approvals to be made via signatures (EIP-2612)
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, Context {
    using Counters for Counters.Counter;
    
    mapping(address => Counters.Counter) private _nonces;
    
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;
    
    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;
    
    constructor(string memory name) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes("1"));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
        
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
    }
    
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");
        
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                owner,
                spender,
                value,
                _nonces[owner].current(),
                deadline
            )
        );
        
        bytes32 hash = _hashTypedDataV4(structHash);
        
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");
        
        _nonces[owner].increment();
        _approve(owner, spender, value);
    }
    
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }
    
    function DOMAIN_SEPARATOR() public view virtual override returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }
    
    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                nameHash,
                versionHash,
                block.chainid,
                address(this)
            )
        );
    }
    
    function _hashTypedDataV4(bytes32 structHash) private view returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    structHash
                )
            )
        );
    }
}
