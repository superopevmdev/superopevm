// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IERC20Permit
 * @dev Interface for the Permit functionality (EIP-2612)
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature.
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
