// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;
import "hardhat/console.sol";

import "./Helpers/ISwapRouter.sol";
import "./Helpers/TransferHelper.sol";

 contract Swap {
     ISwapRouter public immutable swapRouter;
     // Mainet
    //  address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    //  address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    //  address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

     address public constant DAI = 0xaD6D458402F60fD3Bd25163575031ACDce07538D;
     address public constant WETH9 = 0xc778417E063141139Fce010982780140Aa0cD5Ab;


     // For this example, we will set the pool fee to 0.3%.   0.3 * 10000
     uint24 public constant poolFee = 3000;

     constructor() {
         swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
     }

    /// @notice swapExactInputSingle swaps a fixed amount of DAI for a maximum possible amount of WETH9
    /// using the DAI/WETH9 0.3% pool by calling `exactInputSingle` in the swap router.
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its DAI for this function to succeed.
    /// @param amountIn The exact amount of DAI that will be swapped for WETH9.
    /// @return amountOut The amount of WETH9 received.
    function swapExactInputSingle(uint256 amountIn) external returns (uint256 amountOut) {
        // msg.sender must approve this contract
        // Do it manually by interacting with token's original contract (From etherscan or via frontend)

        // Transfer the specified amount of DAI to this contract.
        // Transfers tokens from msg.sender to a recipient
        TransferHelper.safeTransferFrom(DAI, msg.sender, address(this), amountIn);

        // Approve the router to spend DAI.
        TransferHelper.safeApprove(DAI, address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: DAI,
            tokenOut: WETH9,
            fee: poolFee,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0, // Output will not fallBelow this value
            sqrtPriceLimitX96: 0
        });

        amountOut = swapRouter.exactInputSingle(params);
 }

    function swapExactOutputSingle(uint256 _amountOut, uint256 _amountInMaximum) external returns(uint amountIn) {
        // Aprove this contract for amountInMaxmimum

        // Transfer from msg.sender to this Contract
        TransferHelper.safeTransferFrom(DAI, msg.sender, address(this), _amountInMaximum);

        // Approve to router
        TransferHelper.safeApprove(DAI, address(swapRouter), _amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: DAI,
            tokenOut: WETH9,
            fee: poolFee,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountOut: _amountOut,
            amountInMaximum: _amountInMaximum,
            sqrtPriceLimitX96: 0
        });

        amountIn = swapRouter.exactOutputSingle(params);

        if(amountIn < _amountInMaximum) {
            // Make a refund to sender
            // First we approved router all input. Router transfer itself the usable amount.
            // Leftover amount is still in approval
            // We will set approval to zero. 
            TransferHelper.safeApprove(DAI, address(swapRouter), 0);

            // As Router has not touched the leftover amount from approvals, so it will be still our contract owns
            // We will transfer it to sender
            TransferHelper.safeTransfer(DAI, msg.sender, _amountInMaximum - amountIn);
        }
    }
 }