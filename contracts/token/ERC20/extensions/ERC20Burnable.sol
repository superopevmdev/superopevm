// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20 as ERC20} from "@superopevm/contracts/token/ERC20/ERC20.sol";
import {Context as Context} from "@superopevm/contracts/utils/Context.sol";

/**
 * @dev Extension of ERC20 that allows token holders to destroy tokens
 */
abstract contract ERC20Burnable is Context, ERC20 {
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}
