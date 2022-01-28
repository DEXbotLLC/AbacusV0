// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import "../lib/IUniswapV2Pair.sol";
import "../lib/IUniswapV2Router02.sol";
import "../lib/ISwapRouter.sol";
import "../lib/WETH.sol";


/// @title AbacusV0. The on-chain logic to trustlessly swap tokens through DEXbot (https://dexbot.io/). 
/// @author 0xKitsune (https://github.com/0xKitsune)
/// @notice This contract enables DEXbot and other off-chain automated transaction curators to create swaps trustlessly while extracting a fee for off-chain services.
/// @notice In plain english, DEXbot is an automated way to sell your tokens. This contract allows DEXbot's off-chain logic to create swap transactions and return the payout to the msg.sender trustlessly.
/// @dev the DEXbot client source code is open source and you can check out how it works or read the whitepaper here: (https://github.com/DEXbotLLC/DEXbot_Client).
contract AbacusV0 {
    

    address private _owner;

    address private _abacusWallet;

    IUniswapV2Router02 IUniV2Router; 

    ISwapRouter IUniV3Router;

    /// @notice Wrapped native token address for the chain (NATO). Ex. WETH for Ethereum L1, WMATIC for Polygon, WBNB for BSC.
    address public constant WNATO_ADDRESS;

    /// @notice WETH interface to unwrap wrapped native tokens resulting from token swaps.
    WETH private _wnato;


    /// @notice divided by 1000 during calculations so the percent is actually a maximum of 3% during the calculation
    uint constant MAX_ABACUS_FEE_MUL_1000 = 30 ;

    /// @notice divided by 1000 during calculations so the percent is actually 2.5% during the calculation
    uint abacusFeeMul1000 =25;


/// @notice 
/// @param 
constructor(address _wnatoAddress, address _uniV2Router, address _uniV3Router){
    _owner = msg.sender;
    _abacusWallet=msg.sender;
    
    //initialize weth
    _wnato=WETH(_wnatoAddress);
    //initialize wrapped native token address
    WNATO_ADDRESS=_wnatoAddress;

    //initialize univ2router
    IUniV2Router = IUniV2Router(_uniV2Router);
    //initialize univ3router
    IUniV3Router = ISwapRouter(_uniV3Router);
}


    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

/// @notice swap and transfer to the chain's native token
modifier onlyOwner() {
    require(msg.sender==_owner, "!owner");
    _;
}

/// @notice swap and transfer to the chain's native token
function swapAndTransferUnwrappedNatoWithV2 (bytes calldata _callData) external {
    //unpack the call data
    (uint _amountIn, uint _amountOutMin, address _tokenToSwap, uint _deadline) = abi.decode(_callData, (uint, uint, address, uint));

    //swap tokens for weth
    uint amountRecieved = IUniV2Router.swapExactTokensForTokens(_amountIn, _amountOutMin, [_tokenToSwap, WETH_ADDRESS], address(this), _deadline)[1];

    //unwrap weth
    _wnato.withdraw(amountRecieved);

    //calculate the amount out less abacus fee
    (uint payout, uint abacusFee) = calculatePayoutLessAbacusFee(amountRecieved);

    //send the amount out less abacus fee to the msg.sender
    SafeTransferLib.safeTransferETH(msg.sender, payout);

    //send the abacus fee to the _abacusWallet wallet
    SafeTransferLib.safeTransferETH(_abacusWallet, abacusFee);

}



/// @notice swap and transfer to the chain's native token
function swapAndTransferUnwrappedNatoSupportingFeeOnTransferTokensWithV2 (address _lp) external {
    //unpack the call data
    (uint _amountIn, uint _amountOutMin, address _tokenToSwap, uint _deadline) = abi.decode(_callData, (uint, uint, address, uint));

    //swap tokens for weth
    uint amountRecieved = IUniV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_amountIn, _amountOutMin, [_tokenToSwap, WETH_ADDRESS], address(this), _deadline)[1];

    //unwrap weth
    _wnato.withdraw(amountRecieved);

    //calculate the amount out less abacus fee
    (uint payout, uint abacusFee) = calculatePayoutLessAbacusFee(amountRecieved);

    //send the amount out less abacus fee to the msg.sender
    SafeTransferLib.safeTransferETH(msg.sender, payout);

    //send the abacus fee to the _abacusWallet wallet
    SafeTransferLib.safeTransferETH(_abacusWallet, abacusFee);
}


/// @notice swap and transfer to the chain's native token with V3 interface
function swapAndTransferUnwrappedNatoWithV3 (bytes calldata _callData) external {
        (address tokenIn,
        address tokenOut,
        uint24 fee,
        address recipient,
        uint256 deadline,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint160 sqrtPriceLimitX96) = abi.decode(_callData, (address,address,uint24,address,uint256,uint256,uint256,uint160));

     uint amountRecieved = IUniV3Router.exactInputSingle(ExactInputSingleParams(tokenIn, WNATO_ADDRESS, fee, address(this), deadline, amountIn, amountOutMinimum, sqrtPriceLimitX96));

    //unwrap weth
    _wnato.withdraw(amountRecieved);

    //calculate the amount out less abacus fee
    (uint payout, uint abacusFee) = calculatePayoutLessAbacusFee(amountRecieved);

    //send the amount out less abacus fee to the msg.sender
    SafeTransferLib.safeTransferETH(msg.sender, payout);

    //send the abacus fee to the _abacusWallet wallet
    SafeTransferLib.safeTransferETH(_abacusWallet, abacusFee);
}



/// @notice function to update Abacus fee. Fee can never be greater than 3%
/// fee is divided by 100 when calculating the fee
function setAbacusFee(uint _abacusFeeMul1000) external onlyOwner() {
    require(_abacusFeeMul1000<MAX_ABACUS_FEE_MUL_1000, "!fee<max");
    abacusFeeMul1000=_abacusFeeMul1000;
}


function calculatePayoutLessAbacusFee(uint amountOut) private view returns (uint, uint) {
    uint abacusFee = (amountOut*(abacusFeeMul1000/1000));
    return ((amountOut-abacusFee), abacusFee);
}

function setAbacusWallet(address _newAbacusWallet) external onlyOwner() {
    _abacusWallet=_newAbacusWallet;
}


function transferOwnership(address _newOwner) external onlyOwner() {
    _owner=_newOwner;
}



   
}

