// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "./Helpers/ISwapRouter.sol";
import "./Helpers/TransferHelper.sol";

 contract multihopSwap {
     ISwapRouter public immutable swapRouter;
     uint24 public poolFee = 3000; // 0.3%

    //  Ropsten
     address public constant DAI = 0xaD6D458402F60fD3Bd25163575031ACDce07538D;
     address public constant WETH9 = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
     address public constant USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;

    constructor() {
        swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    }

    // path DAI --> USDC --> WETH
    function swapExactInputMultihop(uint _amountIn) external {
        // Aprove Input token amount to this contract

        // Transfer to this contract
        TransferHelper.safeTransferFrom(DAI, msg.sender, address(this), _amountIn);
        
        // Approve Router
        TransferHelper.safeApprove(DAI, address(swapRouter), _amountIn);

        /* 
        Multiple pool swaps are encoded through bytes called a `path`. A path is a sequence of token addresses and
        poolFees that define the pools used in the swaps.
        The format for pool encoding is (tokenIn, fee, tokenOut/tokenIn, fee, tokenOut) where tokenIn/tokenOut parameter
         is the shared token across the pools.
        Since we are swapping DAI to WETH and then WETH to USDC the path encoding is (DAI, 0.3%, WETH, 0.3%, USDC).
        */

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: abi.encodePacked(DAI, poolFee, USDC, poolFee, WETH9),
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: 0 
        });

        swapRouter.exactInput(params);
    } 

    // Not Working Yet. Will look into later
    function swapExactOutputMultihop(uint _amountOut, uint _amountInMaximum) public {
        // Aprove Input token amount to this contract

        // Transfer to this contract
        TransferHelper.safeTransferFrom(DAI, msg.sender, address(this), _amountInMaximum);
        
        // Approve Router
        TransferHelper.safeApprove(DAI, address(swapRouter), _amountInMaximum);

        // For ExactOutput, the will be in reverse order
        // eg. In our example it will be  WETH <-- poolFee <-- USDC <-- poolFee <-- DAI
        // Above transfer will be from DAI to USDC

        ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
            path: abi.encodePacked(WETH9, poolFee, USDC, poolFee, DAI),
            recipient: msg.sender,
            deadline: block.timestamp,
            amountOut: _amountOut,
            amountInMaximum: _amountInMaximum
        });

        uint amountIn = swapRouter.exactOutput(params);

        if(amountIn < _amountInMaximum) {
            TransferHelper.safeApprove(DAI, address(swapRouter), 0);
            TransferHelper.safeTransferFrom(DAI, address(this), msg.sender, _amountInMaximum - amountIn);
        }
    }

        function swapExactOutputMultihopNew(uint256 amountOut, uint256 amountInMaximum) external returns (uint256 amountIn) {
        // Transfer the specified `amountInMaximum` to this contract.
        TransferHelper.safeTransferFrom(DAI, msg.sender, address(this), amountInMaximum);
        // Approve the router to spend  `amountInMaximum`.
        TransferHelper.safeApprove(DAI, address(swapRouter), amountInMaximum);

        // The parameter path is encoded as (tokenOut, fee, tokenIn/tokenOut, fee, tokenIn)
        // The tokenIn/tokenOut field is the shared token between the two pools used in the multiple pool swap. In this case USDC is the "shared" token.
        // For an exactOutput swap, the first swap that occurs is the swap which returns the eventual desired token.
        // In this case, our desired output token is WETH9 so that swap happens first, and is encoded in the path accordingly.
        ISwapRouter.ExactOutputParams memory params =
            ISwapRouter.ExactOutputParams({
                path: abi.encodePacked(WETH9, poolFee, USDC, poolFee, DAI),
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum
            });

        // Executes the swap, returning the amountIn actually spent.
        amountIn = swapRouter.exactOutput(params);

        // If the swap did not require the full amountInMaximum to achieve the exact amountOut then we refund msg.sender and approve the router to spend 0.
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(DAI, address(swapRouter), 0);
            TransferHelper.safeTransferFrom(DAI, address(this), msg.sender, amountInMaximum - amountIn);
        }
    }
 }