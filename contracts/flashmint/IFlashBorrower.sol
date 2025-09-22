// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IFlashBorrower
 * @dev Interface for flash loan borrowers
 */
interface IFlashBorrower {
    /**
     * @dev Called by the flashmint provider during a flash loan
     * @param token The address of the token being loaned
     * @param amount The amount of tokens being loaned
     * @param fee The fee amount to be paid
     * @param data Arbitrary data passed by the borrower
     * @return boolean True if the operation succeeded
     */
    function onFlashLoan(
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bool);
}
