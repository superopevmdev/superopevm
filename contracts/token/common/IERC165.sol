// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @dev Interface of the ERC165 standard
 */
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
