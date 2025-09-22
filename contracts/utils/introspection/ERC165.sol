// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC165 as IERC165} from "@superopevm/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Implementation of the ERC165 standard
 */
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
