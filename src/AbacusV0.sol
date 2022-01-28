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
/// @dev The DEXbot client source code is open source. You can check out how it works or read the whitepaper here: (https://github.com/DEXbotLLC/DEXbot_Client).
contract AbacusV0 {
    
    /// @notice The EOA address that owns the contract. This is set to the msg.sender initially at deployment. In this contract, the _owner can update the abacus fee (which can never be > 3%), set the abacus wallet or transfer ownership. 
    address private _owner;
    
    /// @notice Address of a UniV2 compatible router to swap tokens. This can be set to any UniV2 compatible router (Ex. UniswapV2 or Sushiswap on Ethereum, Pancakeswap on Binance Smart Chain (BSC)).
    address public UniV2RouterAddress; 
    /// @notice Instance of a UniV2 compatible router to swap tokens.
    IUniswapV2Router02 UniV2Router; 

    /// @notice Address of the UniV3 router to swap tokens.
    address public UniV3RouterAddress; 
    /// @notice Instance of the UniV3 router to swap tokens.
    ISwapRouter UniV3Router;

    /// @notice Wrapped native token (WNATO) address for the chain. This address will change depending on the chain the contract is deployed to (Ex. WETH for Ethereum L1, WMATIC for Polygon, WBNB for BSC).
    address public constant WNATO_ADDRESS;

    /// @notice Wrapped ETH contract instance to unwrap WETH to ETH. While this variable is named WETH, it could be any native token depending on the chain the contract is deployed to (Ex. WETH for Ethereum L1, WMATIC for Polygon, WBNB for BSC).
    WETH private _wnato;

    /// @notice divided by 1000 during calculations so the percent is actually a maximum of 3% during the calculation
    uint constant MAX_ABACUS_FEE_MUL_1000 = 30 ;

    /// @notice divided by 1000 during calculations so the percent is actually 2.5% during the calculation
    uint abacusFeeMul1000 =25;

    /// @notice The EOA address that the abacus fee is sent to. This is initially set to the msg.sender.
    address private _abacusWallet;


/// @notice 
/// @param 
constructor(address _wnatoAddress, address _uniV2Router, address _uniV3Router){
    _owner = msg.sender;
    _abacusWallet=msg.sender;
    
    //initialize weth
    _wnato=WETH(_wnatoAddress);
    //initialize wrapped native token address
    WNATO_ADDRESS=_wnatoAddress;

    UniV2RouterAddress=_uniV2Router;

    UniV3RouterAddress=_uniV3Router;

    //initialize univ2router
    UniV2Router = IUniV2Router(_uniV2Router);
    //initialize univ3router
    UniV3Router = ISwapRouter(_uniV3Router);
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

/// @dev change this natspec description but mention approve swap router, not the contract to save gas from unnecessary transfers
function swapAndTransferUnwrappedNatoWithV2 (bytes calldata _callData) external {
    //unpack the call data
    (uint _amountIn, uint _amountOutMin, address _tokenToSwap, uint _deadline) = abi.decode(_callData, (uint, uint, address, uint));

    //swap tokens for weth
    uint amountRecieved = UniV2Router.swapExactTokensForTokens(_amountIn, _amountOutMin, [_tokenToSwap, WETH_ADDRESS], address(this), _deadline)[1];

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
    uint amountRecieved = UniV3Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_amountIn, _amountOutMin, [_tokenToSwap, WETH_ADDRESS], address(this), _deadline)[1];

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

function calculatePayoutLessAbacusFee(uint amountOut) private view returns (uint, uint) {
    uint abacusFee = (amountOut*(abacusFeeMul1000/1000));
    return ((amountOut-abacusFee), abacusFee);
}

function approveAllSwapRouters(address _tokenAddress){
    approveUniV2Router(_tokenAddress);
    approveUniV3Router(_tokenAddress);
}


function approveUniV2Router(address _tokenAddress){
    ERC20(_tokenAddress).approve(UniV2RouterAddress, amount);
}

function approveUniV3Router(address _tokenAddress){
    ERC20(_tokenAddress).approve(UniV3RouterAddress, amount);
}


/// @notice function to update Abacus fee. Fee can never be greater than 3%
/// fee is divided by 100 when calculating the fee
function setAbacusFee(uint _abacusFeeMul1000) external onlyOwner() {
    require(_abacusFeeMul1000<MAX_ABACUS_FEE_MUL_1000, "!fee<max");
    abacusFeeMul1000=_abacusFeeMul1000;
}



function setAbacusWallet(address _newAbacusWallet) external onlyOwner() {
    _abacusWallet=_newAbacusWallet;
}


function transferOwnership(address _newOwner) external onlyOwner() {
    _owner=_newOwner;
}



   
}

