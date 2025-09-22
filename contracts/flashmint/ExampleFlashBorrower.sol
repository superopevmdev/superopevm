// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IFlashBorrower as IFlashBorrower} from "@superopevm/contracts/flashmint/IFlashBorrower.sol";
import {IERC20 as IERC20} from "@superopevm/contracts/token/ERC20/IERC20.sol";
import {Flashmint as Flashmint} from "@superopevm/contracts/flashmint/Flashmint.sol";

/**
 * @title ExampleFlashBorrower
 * @dev Example implementation of a flash loan borrower
 */
contract ExampleFlashBorrower is IFlashBorrower {
    Flashmint public flashmint;
    address public token;
    
    event FlashLoanReceived(uint256 amount, uint256 fee);
    
    constructor(address _flashmint, address _token) {
        flashmint = Flashmint(_flashmint);
        token = _token;
    }
    
    /**
     * @dev Initiate a flash loan
     * @param amount The amount to borrow
     */
    function requestFlashLoan(uint256 amount) external {
        uint256 fee = flashmint.calculateFee(amount);
        uint256 repaymentAmount = amount + fee;
        
        // Approve repayment
        IERC20(token).approve(address(flashmint), repaymentAmount);
        
        // Initiate flash loan
        bytes memory data = abi.encode("Example Flash Loan");
        flashmint.flashLoan(token, amount, data);
    }
    
    /**
     * @dev Flash loan callback implementation
     * @param _token The token address
     * @param amount The borrowed amount
     * @param fee The fee amount
     * @param data Arbitrary data
     * @return True if successful
     */
    function onFlashLoan(
        address _token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bool) {
        require(msg.sender == address(flashmint), "Unauthorized caller");
        require(_token == token, "Invalid token");
        
        // Execute business logic (arbitrage, liquidation, etc.)
        // This is where you'd implement your custom logic
        emit FlashLoanReceived(amount, fee);
        
        // Repay loan (already approved)
        uint256 repaymentAmount = amount + fee;
        IERC20(token).transferFrom(
            address(this),
            address(flashmint),
            repaymentAmount
        );
        
        return true;
    }
    
    /**
     * @dev Allow contract to receive tokens
     * @param amount The amount to deposit
     */
    function depositTokens(uint256 amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }
}
