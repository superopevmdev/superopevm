// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20Permit as ERC20Permit} from "@superopevm/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @title draft-ERC20Permit
 * @dev Draft implementation of ERC20Permit for testing purposes
 */
abstract contract draftERC20Permit is ERC20Permit {
    constructor(string memory name) ERC20Permit(name) {}
}
