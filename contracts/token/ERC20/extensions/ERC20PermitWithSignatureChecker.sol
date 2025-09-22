// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20Permit as IERC20Permit} from "@superopevm/contracts/interfaces/IERC20Permit.sol";
import {ERC20 as ERC20} from "@superopevm/contracts/token/ERC20/ERC20.sol";
import {SignatureChecker as SignatureChecker} from "@superopevm/contracts/utils/cryptography/SignatureChecker.sol";
import {Counters as Counters} from "@superopevm/contracts/utils/math/Counters.sol";
import {EIP712 as EIP712} from "@superopevm/contracts/utils/cryptography/EIP712.sol";

/**
 * @title ERC20PermitWithSignatureChecker
 * @dev ERC20Permit implementation using SignatureChecker
 */
abstract contract ERC20PermitWithSignatureChecker is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;
    
    mapping(address => Counters.Counter) private _nonces;
    
    bytes32 private constant _PERMIT_TYPEHASH = 
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    
    constructor(string memory name) EIP712(name, "1") {}
    
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override(IERC20Permit) {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");
        
        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _nonces[owner].current(),
                deadline
            )
        );
        
        bytes32 hash = _hashTypedDataV4(structHash);
        require(SignatureChecker.isValidSignatureNow(owner, hash, v, r, s), "ERC20Permit: invalid signature");
        
        _nonces[owner].increment();
        _approve(owner, spender, value);
    }
    
    function nonces(address owner) public view virtual override(IERC20Permit) returns (uint256) {
        return _nonces[owner].current();
    }
    
    function DOMAIN_SEPARATOR() public view virtual override(EIP712, IERC20Permit) returns (bytes32) {
        return EIP712.DOMAIN_SEPARATOR();
    }
}
