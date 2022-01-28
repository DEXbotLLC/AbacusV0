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
    
    /// @notice Address of a UniV2 compatible router to swap tokens. This can be set to any UniV2 compatible router (Depending on the chain, this could be Uniswap on Ethereum, Uniswap on Polygon, Pancakeswap on Binance Smart Chain (BSC), ect.).
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

    /// @notice After a swap transaction is completed, a small fee is subtracted from the amountOut. This fee is for the off-chain logic/computations to curate automated swap transactions for an externally owned wallet EOA.
    /// @notice During the fee calculation, this value is divided by 1000 to effectively multiply by a decimal (Ex. If abacusFeeMul1000 is 25, then amountOut*(abacusFeeMul1000/1000) is equivalent to amountOut*.025).
    uint public abacusFeeMul1000;

    /// @notice The maximum abacus fee that can be set. 
    /// @notice The max fee is 3% and the abacus fee can never be set above this value.
    /// @notice This value is divided by 1000 during calculations so with the maximum fee being 30, it can be expressed during calculations as MAX_ABACUS_FEE_MUL_1000/1000 which equals 30/1000 or .03 or 3%.
    uint constant MAX_ABACUS_FEE_MUL_1000 = 30 ;

    /// @notice The EOA address that the abacus fee is sent to. This is initially set to the msg.sender.
    address private _abacusWallet;


/// @notice Constructor to initialize the contract on deployment.
/// @param _wnatoAddress The wrapped native token address (Ex. WETH for Ethereum L1, WMATIC for Polygon, WBNB for BSC).
/// @param _uniV2Router The address of the uniV2 compatible router. Depending on the chain, this could be Uniswap on Ethereum, Uniswap on Polygon, Pancakeswap on Binance Smart Chain (BSC), ect. You can check the router address by calling the UniV2RouterAddress variable.
/// @param _uniV3Router The address of the uniV3 router.
constructor(address _wnatoAddress, address _uniV2Router, address _uniV3Router){
   
    /// @notice Set the owner of the contract to the msg.sender that deployed the contract.
    _owner = msg.sender;

    /// @notice Set the abacus wallet to the msg.sender that deployed the contract.
    _abacusWallet=msg.sender;
    
    /// @notice Set the initial abacus fee to 2.5%
    abacusFeeMul1000=25;

    /// @notice Initialize the wrapped native token address for the chain.
    WNATO_ADDRESS=_wnatoAddress;

    /// @notice Initialize the wrapped ETH contract instance with the wrapped native token address for the chain.
    _wnato=WETH(_wnatoAddress);

    /// @notice Initialize the UniV2Router address.
    UniV2RouterAddress=_uniV2Router;

    /// @notice Initialize the UniV3Router address.
    UniV3RouterAddress=_uniV3Router;

    /// @notice Initialize the UniV2Router contract instance.
    UniV2Router = IUniV2Router(_uniV2Router);

    /// @notice Initialize the UniV3Router contract instance.
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

/// @notice 

/// @dev change this natspec description but mention approve swap router, not the contract to save gas from unnecessary transfers
function swapAndTransferUnwrappedNatoWithV2 (bytes calldata _callData) external {

    /// @notice unpack the call data.
    (uint _amountIn, uint _amountOutMin, address _tokenToSwap, uint _deadline) = abi.decode(_callData, (uint, uint, address, uint));

    /// @notice Swap tokens for wrapped native tokens (nato).
    uint amountRecieved = UniV2Router.swapExactTokensForTokens(_amountIn, _amountOutMin, [_tokenToSwap, WETH_ADDRESS], address(this), _deadline)[1];

    /// @notice Unwrap wrapped nato to nato for the amount recieved from the swap.
    _wnato.withdraw(amountRecieved);

    /// @notice Calculate the payout less abacus fee.
    (uint payout, uint abacusFee) = calculatePayoutLessAbacusFee(amountRecieved);

    /// @notice Send the payout (amount out less abacus fee) to the msg.sender
    SafeTransferLib.safeTransferETH(msg.sender, payout);

    /// @notice Send the abacus fee to the abacus wallet.
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

