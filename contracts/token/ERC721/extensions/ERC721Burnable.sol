// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC721 as ERC721} from "@superopevm/contracts/token/ERC721/ERC721.sol";
import {Context as Context} from "@superopevm/contracts/utils/Context.sol";

/**
 * @dev Extension of ERC721 that allows token holders to destroy tokens
 */
abstract contract ERC721Burnable is Context, ERC721 {
    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}
