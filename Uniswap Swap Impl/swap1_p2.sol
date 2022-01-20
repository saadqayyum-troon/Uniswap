// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./Helpers/ISwapRouter.sol";
import "./Helpers/TransferHelper.sol";

// This Contract is for conversion of ETH to ERC20



interface IUniSwapRouter is ISwapRouter {
    function refundETH() external payable;
    // This is a function which swapRouter address can also call because this function is present in
    // a parent contract of swapRouter. It is inside PeripheryPayments.sol
}


contract swap {
    IUniSwapRouter public immutable swapRouter;

    // We will pick the pool of WETH and DAI which has a pool fee of 0.3 % ->  0.3 * 10000 = 3000
    uint24 public constant poolFee = 3000;

    // Ropsten Token Addresses
    address public WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address public DAI = 0xaD6D458402F60fD3Bd25163575031ACDce07538D;

    constructor() {
        swapRouter = IUniSwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    }

        


    function swapExactInputSingle() public payable {
        require(msg.value > 0, "Must pass Eth for conversion");

        // Uniswap Router under the hood transforms Eth to Weth automatically. So we will trade Weth
        // 1ETH = 1WETH

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH,
            tokenOut: DAI,
            fee: poolFee,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: msg.value,

            /** For safety set minimum output you want. If output falls below your set value, execution will be reverted
            to save your loss that you dont want.
             It will throw "execution reverted: Too litle received" */
            amountOutMinimum: 1,  // 0.000000000000000001 DAI. Smallest Unit 10^18
            sqrtPriceLimitX96: 0
        });

        // Must give value to router so he can transform eth to weth and do conversion to dai
         swapRouter.exactInputSingle{value: msg.value}(params);
    }

    function swapExactOutputSingle(uint _amountOut) public payable {
        require(msg.value > 0, "Must pass Eth for conversion");


        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: WETH,
            tokenOut: DAI,
            fee: poolFee,
            recipient: msg.sender,
            deadline: block.timestamp,

            // Here we will set amountOut. How much we want in output, not caring about exactInputSingle
            amountOut: _amountOut,

            // Maximm amount of Input you want to spend to get desired output value
            // Leftover input token will be refunded
            amountInMaximum: msg.value,
            sqrtPriceLimitX96: 0
        });

        swapRouter.exactOutputSingle{value: msg.value}(params);

        // Refund Leftover Eth
        swapRouter.refundETH(); // Router will refund to this contract
        // Transfer to msg.sender
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Refund Failed");
    }

    // Implement a Fallback to receive Ether
        // This function is called for plain Ether transfers, i.e  for every call with empty calldata.
        // For also receiving msg.data as well as Ether, we need fallback.
        receive() external payable {}

}