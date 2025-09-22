// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC721 as IERC721} from "@superopevm/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC721 standard
 */
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
