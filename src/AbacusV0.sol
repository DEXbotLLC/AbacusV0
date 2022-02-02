// SPDX-License-Identifier: TODO
pragma solidity >=0.8.10;

import "../lib/IUniswapV2Pair.sol";
import "../lib/IUniswapV2Router02.sol";
import "../lib/ISwapRouter.sol";
import "../lib/WETH.sol";

//TODO: set custom fee mapping and a function that is onlyOwner to set the custom fees


/// @title AbacusV0. The on-chain logic to trustlessly swap tokens through DEXbot (https://dexbot.io/). 
/// @author 0xKitsune (https://github.com/0xKitsune)
/// @notice This contract enables DEXbot and other off-chain automated transaction curators to create swaps trustlessly while extracting a fee for off-chain services.
/// @notice In plain english, DEXbot is an automated way to sell your tokens. This contract allows DEXbot's off-chain logic to create swap transactions and return the payout to the msg.sender trustlessly.
/// @dev The DEXbot client source code is open source. You can check out how it works or read the whitepaper here: (https://github.com/DEXbotLLC/DEXbot_Client).
contract AbacusV0 {


    /// @notice The EOA address that owns the contract. This is set to the msg.sender initially at deployment. In this contract, the _owner can update the abacus fee (which can never be > 3%), set the abacus wallet or transfer ownership. 
    address private _owner;
    
    /// @notice Address of a UniV2 compatible router to swap tokens. This can be set to any UniV2 compatible router (Depending on the chain, this could be Uniswap on Ethereum, Uniswap on Polygon, Pancakeswap on Binance Smart Chain (BSC), ect.).
    address public uniV2RouterAddress; 

    /// @notice Instance of a UniV2 compatible router to swap tokens.
    IUniswapV2Router02 UniV2Router; 

    /// @notice Address of the UniV3 router to swap tokens.
    address public uniV3RouterAddress; 

    /// @notice Instance of the UniV3 router to swap tokens.
    ISwapRouter UniV3Router;

    /// @notice Wrapped native token (WNATO) address for the chain. This address will change depending on the chain the contract is deployed to (Ex. WETH for Ethereum L1, WMATIC for Polygon, WBNB for BSC).
    address public wnatoAddress;

    /// @notice Wrapped ETH contract instance to unwrap WETH to ETH. While this variable is named WETH, it could be any native token depending on the chain the contract is deployed to (Ex. WETH for Ethereum L1, WMATIC for Polygon, WBNB for BSC).
    WETH private _wnato;

    /// @notice After a swap transaction is completed, a small fee is subtracted from the amountOut. This fee is for the off-chain logic/computations to curate automated swap transactions for an externally owned wallet EOA.
    /// @notice During the fee calculation, this value is divided by 1000 to effectively multiply by a decimal (Ex. If abacusFeeMul1000 is 25, then amountOut*(abacusFeeMul1000/1000) is equivalent to amountOut*.025).
    uint public abacusFeeMul1000;

    /// @notice The maximum abacus fee that can be set. 
    /// @notice The max fee is 3% and the abacus fee can never be set above this value.
    /// @notice This value is divided by 1000 during calculations so with the maximum fee being 30, it can be expressed during calculations as MAX_ABACUS_FEE_MUL_1000/1000 which equals 30/1000 or .03 or 3%.
    uint constant MAX_ABACUS_FEE_MUL_1000 = 30 ;
 
    /// @notice Mapping to hold custom abacus fees for specific externally owned wallets to reduce fees for that wallet. Mapping is wallet address -> token address -> custom fee
    mapping(address => mapping(address => uint256)) public addressToCustomFee;

/// @notice Constructor to initialize the contract on deployment.
/// @param _wnatoAddress The wrapped native token address (Ex. WETH for Ethereum L1, WMATIC for Polygon, WBNB for BSC).
/// @param _uniV2Router The address of the uniV2 compatible router. Depending on the chain, this could be Uniswap on Ethereum, Uniswap on Polygon, Pancakeswap on Binance Smart Chain (BSC), ect. You can check the router address by calling the UniV2RouterAddress variable.
/// @param _uniV3Router The address of the uniV3 router.
constructor(address _wnatoAddress, address _uniV2Router, address _uniV3Router){
   
    /// @notice Set the owner of the contract to the msg.sender that deployed the contract.
    _owner = msg.sender;

    /// @notice Set the initial abacus fee to 2.5%
    abacusFeeMul1000=25;

    /// @notice Initialize the wrapped native token address for the chain.
    wnatoAddress=_wnatoAddress;

    /// @notice Initialize the wrapped ETH contract instance with the wrapped native token address for the chain.
    _wnato=WETH(payable(_wnatoAddress));

    /// @notice Initialize the UniV2Router address.
    uniV2RouterAddress=_uniV2Router;

    /// @notice Initialize the UniV2Router contract instance.
    UniV2Router = IUniswapV2Router02(_uniV2Router);

    /// @notice Initialize the UniV3Router address.
    uniV3RouterAddress=_uniV3Router;

    /// @notice Initialize the UniV3Router contract instance.
    UniV3Router = ISwapRouter(_uniV3Router);


}

/// @notice Modifier that checks if the msg.sender is the owner of the contract. The only functions that are set as onlyOwner() are setAbacusFee, setAbacusWallet and transferOwnership.
modifier onlyOwner() {
    require(msg.sender==_owner, "!owner");
    _;
}


receive() external payable {
}

fallback() external payable {
}


/// @notice This function uses a UniV2 compatible router to swap a token for the wrapped native token, unwraps the native token and sends the amountOut minus the abacus fee back to the msg.sender.
/// @param _callData This param is abi encoded bytes containing the amountIn and the amountOutMin for the swap, the token to swap from and the transaction deadline for the swap.  
/// @dev To create the abi encoded calldata, simply use abi.encode(_amountIn,_amountOutMin,_tokenToSwap,_deadline).
/// @dev _amountIn is the exact amount of tokens you want to swap.
/// @dev _amountOutMin is the minimum amount of tokens you want resulting from the swap.
/// @dev _tokenIn is the address of the token that you want to swap from (Ex. When swapping from $LINK to $ETH, _tokenToSwap is the address for $LINK).
/// @dev _deadline is the unix time after which a swap will fail, to protect against long-pending transactions and wild swings in prices.
/// @dev The swap router must be approved for this to function to succeed. Since tokens are never sent to the Abacus contract before the swap, the Abacus does not need to be approved. 
/// @dev This contract saves gas by only having to send the tokens to the router vs sending tokens to the contract, and then sending tokens to the router.
function swapAndTransferUnwrappedNatoWithV2 (bytes calldata _callData) external {

    /// @notice Decode the call data.
    (uint _amountIn, uint _amountOutMin, address _tokenIn, uint _deadline) = abi.decode(_callData, (uint, uint, address, uint));

    /// @notice Set the routing path for the swap to be _tokenToSwap to wnatoAddress
    address[] memory path = new address[](2);
    path[0]=_tokenIn;
    path[1]=wnatoAddress;

    /// @notice Send the tokens to the Abacus contract
    SafeTransferLib.safeTransferFrom(ERC20(_tokenIn), msg.sender, address(this), _amountIn);

    /// @notice Swap tokens for wrapped native tokens (nato).
    uint amountRecieved = UniV2Router.swapExactTokensForTokens(_amountIn, _amountOutMin, path, address(this), _deadline)[1];

    /// @notice The contract stores the native tokens so that the msg.sender does not have to pay for gas to unwrap WETH. 
    /// @notice If the contract does not have enough of the native token to send the amountRecieved to the msg.sender, the unwrap function will be called on the contract balance.
    /// @dev This functionality is always trustless and will benefit the end user. When the contract has enough native tokens to send the amountRecieved, the end user does not incur the gas fees of unwrapping.
    /// @dev The contract can always send the amountRecieved even when it does not have enough native token balance. The contract will unwrap it's wrapped native tokens and then send the amountRecieved to the user. 
    if (amountRecieved>address(this).balance){
        /// @notice Unwrap the native token balance on the contract to supply the unwrapped native token
        _wnato.withdraw(_wnato.balanceOf(address(this)));
    }

    /// @notice Calculate the payout less abacus fee.
    (uint payout) = calculatePayoutLessAbacusFee(amountRecieved, msg.sender, _tokenIn);

    /// @notice Send the payout (amount out less abacus fee) to the msg.sender
    SafeTransferLib.safeTransferETH(msg.sender, payout);
}



function approveSwapAndTransferUnwrappedNatoWithV2 (bytes calldata _callData) external payable {

    /// @notice Decode the call data.
    (uint _amountIn, uint _amountOutMin, address _tokenIn, uint _deadline) = abi.decode(_callData, (uint, uint, address, uint));

    /// @notice Set the routing path for the swap to be _tokenToSwap to wnatoAddress
    address[] memory path = new address[](2);
    path[0]=_tokenIn;
    path[1]=wnatoAddress;

    /// @notice Send the tokens to the Abacus contract
    SafeTransferLib.safeTransferFrom(ERC20(_tokenIn), msg.sender, address(this), _amountIn);

    /// @notice approve the swap router to interact with the token 
    approveUniV2Router(_tokenIn, (2**256-1));

    /// @notice Swap tokens for wrapped native tokens (nato).
    uint amountRecieved = UniV2Router.swapExactTokensForTokens(_amountIn, _amountOutMin, path, address(this), _deadline)[1];

    /// @notice The contract stores the native tokens so that the msg.sender does not have to pay for gas to unwrap WETH. 
    /// @notice If the contract does not have enough of the native token to send the amountRecieved to the msg.sender, the unwrap function will be called on the contract balance.
    /// @dev This functionality is always trustless and will benefit the end user. When the contract has enough native tokens to send the amountRecieved, the end user does not incur the gas fees of unwrapping.
    /// @dev The contract can always send the amountRecieved even when it does not have enough native token balance. The contract will unwrap it's wrapped native tokens and then send the amountRecieved to the user. 
    if (amountRecieved>address(this).balance){
        /// @notice Unwrap the native token balance on the contract to supply the unwrapped native token
        _wnato.withdraw(_wnato.balanceOf(address(this)));
    }

    /// @notice Calculate the payout less abacus fee.
    (uint payout) = calculatePayoutLessAbacusFee(amountRecieved, msg.sender, _tokenIn);

    /// @notice Send the payout (amount out less abacus fee) to the msg.sender
    SafeTransferLib.safeTransferETH(msg.sender, payout);
}


/// @notice This function uses a UniV2 compatible router to swap a token supporting fee on transfer tokens for the wrapped native token, unwraps the native token and sends the amountOut minus the abacus fee back to the msg.sender.
/// @param _callData This param is abi encoded bytes containing the amountIn and the amountOutMin for the swap, the token to swap from and the transaction deadline for the swap.  
/// @dev To create the abi encoded calldata, simply use abi.encode(_amountIn,_amountOutMin,_tokenToSwap,_deadline).
/// @dev _amountIn is the exact amount of tokens you want to swap.
/// @dev _amountOutMin is the minimum amount of tokens you want resulting from the swap.
/// @dev _tokenIn is the address of the token that you want to swap from (Ex. When swapping from $LINK to $ETH, _tokenToSwap is the address for $LINK).
/// @dev _deadline is the unix time after which a swap will fail, to protect against long-pending transactions and wild swings in prices.
/// @dev The swap router must be approved for this to function to succeed. Since tokens are never sent to the Abacus contract before the swap, the Abacus does not need to be approved. 
/// @dev This contract saves gas by only having to send the tokens to the router vs sending tokens to the contract, and then sending tokens to the router.
function swapAndTransferUnwrappedNatoSupportingFeeOnTransferTokensWithV2 (bytes calldata _callData) external {

    /// @notice Decode the call data.
    (uint _amountIn, uint _amountOutMin, address _tokenIn, uint _deadline) = abi.decode(_callData, (uint, uint, address, uint));


    /// @notice Set the routing path for the swap to be _tokenToSwap to wnatoAddress
    address[] memory path = new address[](2);
    path[0]=_tokenIn;
    path[1]=wnatoAddress;

    /// @dev It is necessary to get the wrapped native token balance before and after the swap because swapExactTokensForTokensSupportingFeeOnTransferTokens does not return the amountOut from the swap.
    uint balanceBefore = _wnato.balanceOf(address(this));

    /// @notice Swap tokens supporting fee on transfer tokens for wrapped native tokens (nato).
    UniV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_amountIn, _amountOutMin, path, address(this), _deadline);
   
    /// @dev Subtract the new balance of wrapped native tokens from the balance before to get the amountRecieved from the swap.
    uint amountRecieved = _wnato.balanceOf(address(this)) - balanceBefore;

    /// @notice The contract stores the native tokens so that the msg.sender does not have to pay for gas to unwrap WETH. 
    /// @notice If the contract does not have enough of the native token to send the amountRecieved to the msg.sender, the unwrap function will be called on the contract balance.
    /// @dev This functionality is always trustless and will benefit the end user. When the contract has enough native tokens to send the amountRecieved, the end user does not incur the gas fees of unwrapping.
    /// @dev The contract can always send the amountRecieved even when it does not have enough native token balance. The contract will unwrap it's wrapped native tokens and then send the amountRecieved to the user. 
    if (amountRecieved>address(this).balance){
        /// @notice Unwrap the native token balance on the contract to supply the unwrapped native token
        _wnato.withdraw(_wnato.balanceOf(address(this)));

    }

    /// @notice Calculate the payout less abacus fee.
    (uint payout) = calculatePayoutLessAbacusFee(amountRecieved, msg.sender, _tokenIn);

    /// @notice Send the payout (amount out less abacus fee) to the msg.sender
    SafeTransferLib.safeTransferETH(msg.sender, payout);
}


function approveSwapAndTransferUnwrappedNatoSupportingFeeOnTransferTokensWithV2 (bytes calldata _callData) external {

    /// @notice Decode the call data.
    (uint _amountIn, uint _amountOutMin, address _tokenIn, uint _deadline) = abi.decode(_callData, (uint, uint, address, uint));


    /// @notice Set the routing path for the swap to be _tokenToSwap to wnatoAddress
    address[] memory path = new address[](2);
    path[0]=_tokenIn;
    path[1]=wnatoAddress;

    /// @dev It is necessary to get the wrapped native token balance before and after the swap because swapExactTokensForTokensSupportingFeeOnTransferTokens does not return the amountOut from the swap.
    uint balanceBefore = _wnato.balanceOf(address(this));

    /// @notice Swap tokens supporting fee on transfer tokens for wrapped native tokens (nato).
    UniV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_amountIn, _amountOutMin, path, address(this), _deadline);
   
    /// @dev Subtract the new balance of wrapped native tokens from the balance before to get the amountRecieved from the swap.
    uint amountRecieved = _wnato.balanceOf(address(this)) - balanceBefore;

    /// @notice approve the swap router to interact with the token 
    approveUniV2Router(_tokenIn, (2**256-1));
    
    /// @notice The contract stores the native tokens so that the msg.sender does not have to pay for gas to unwrap WETH. 
    /// @notice If the contract does not have enough of the native token to send the amountRecieved to the msg.sender, the unwrap function will be called on the contract balance.
    /// @dev This functionality is always trustless and will benefit the end user. When the contract has enough native tokens to send the amountRecieved, the end user does not incur the gas fees of unwrapping.
    /// @dev The contract can always send the amountRecieved even when it does not have enough native token balance. The contract will unwrap it's wrapped native tokens and then send the amountRecieved to the user. 
    if (amountRecieved>address(this).balance){
        /// @notice Unwrap the native token balance on the contract to supply the unwrapped native token
        _wnato.withdraw(_wnato.balanceOf(address(this)));

    }

    /// @notice Calculate the payout less abacus fee.
    (uint payout) = calculatePayoutLessAbacusFee(amountRecieved, msg.sender, _tokenIn);

    /// @notice Send the payout (amount out less abacus fee) to the msg.sender
    SafeTransferLib.safeTransferETH(msg.sender, payout);
}



/// @notice This function uses the UniV3 router to swap a token for the wrapped native token, unwraps the native token and sends the amountOut minus the abacus fee back to the msg.sender.
/// @notice This function utilizes the ISwapRouter.exactInputSingle function which swaps an exact amount of token A for the maximum amount of token B.
/// @param _callData This param is abi encoded bytes containing the ExactInputSingleParams struct required to interact with the ISwapRouter exactInputSingle method.  
/// @dev To create the abi encoded calldata, simply use abi.encode(_tokenIn,_tokenOut,_fee,_recipient,_deadline,_amountIn,_amountOutMinimum,_sqrtPriceLimitX96).
/// @notice Struct to send data to the Uniswap V3 Router exactInputSingle method.
/// @dev _tokenIn is the contract address of the inbound token.
/// @dev _fee is the fee tier of the pool, used to determine the correct pool contract in which to execute the swap.
/// @dev _deadline is the unix time after which a swap will fail, to protect against long-pending transactions and wild swings in prices.
/// @dev _amountIn is the exact amount of tokens you want to swap.
/// @dev _amountOutMinimum is the minimum amount of tokens you want resulting from the swap.
/// @dev _sqrtPriceLimitX96 can be used to set the limit for the price the swap will push the pool to, which can help protect against price impact or for setting up logic in a variety of price-relevant mechanisms/// @dev The swap router must be approved for this to function to succeed. Since tokens are never sent to the Abacus contract before the swap, the Abacus does not need to be approved. 
/// @dev This contract saves gas by only having to send the tokens to the router vs sending tokens to the contract, and then sending tokens to the router.
/// @dev IMPORTANT! Always check that the uniV3Address before using this function. Some networks do not have a univ3 interface and the constructor will set this address to 0. 
/// @dev The DEXbot client accounts for this but if you are calling this function directly, make sure to check the address first.
function swapAndTransferUnwrappedNatoWithV3 (bytes calldata _callData) external {

    /// @notice Decode the call data.
    (address _tokenIn, uint24 _fee ,uint256 _deadline,uint256 _amountIn, uint256 _amountOutMinimum, uint160 _sqrtPriceLimitX96) = abi.decode(_callData, (address,uint24,uint256,uint256,uint256,uint160));

    ///@notice Swap exact input tokens for maximum amount of wrapped native tokens.
    uint amountRecieved = UniV3Router.exactInputSingle(ISwapRouter.ExactInputSingleParams(_tokenIn, wnatoAddress, _fee, address(this), _deadline, _amountIn, _amountOutMinimum, _sqrtPriceLimitX96));

    /// @notice The contract stores the native tokens so that the msg.sender does not have to pay for gas to unwrap WETH. 
    /// @notice If the contract does not have enough of the native token to send the amountRecieved to the msg.sender, the unwrap function will be called on the contract balance.
    /// @dev This functionality is always trustless and will benefit the end user. When the contract has enough native tokens to send the amountRecieved, the end user does not incur the gas fees of unwrapping.
    /// @dev The contract can always send the amountRecieved even when it does not have enough native token balance. The contract will unwrap it's wrapped native tokens and then send the amountRecieved to the user. 
    if (amountRecieved>address(this).balance){
        /// @notice Unwrap the native token balance on the contract to supply the unwrapped native token
        _wnato.withdraw(_wnato.balanceOf(address(this)));

    }

    /// @notice Calculate the payout less abacus fee.
    (uint payout) = calculatePayoutLessAbacusFee(amountRecieved, msg.sender, _tokenIn);

    /// @notice Send the payout (amount out less abacus fee) to the msg.sender
    SafeTransferLib.safeTransferETH(msg.sender, payout);

}

/// @notice Function to calculate abacus fee amount.
/// @dev The abacus fee is divided by 1000 when calculating the fee amount to effectively use float point calculations.
function calculatePayoutLessAbacusFee(uint _amountOut, address _address, address _token) public view returns (uint) {
   
    /// @notice If the address has a custom fee, use the custom fee in the payout calculation, otherwise, use the default abacusFee
    uint customFeeMul1000 = addressToCustomFee[_address][_token];
    if (customFeeMul1000 == 0){
        uint abacusFee = mulDiv(_amountOut, abacusFeeMul1000, 1000);
        return ((_amountOut - abacusFee));
    }else{
        uint abacusFee = mulDiv(_amountOut, customFeeMul1000, 1000);
        return ((_amountOut - abacusFee));
    }
}


/// @notice Function to update abacus fee. The fee can be set to any value between 0% and 3%. This contract is hard coded to never be able to set the fee to be greater than 3%
/// @dev The abacus fee is divided by 1000 when calculating the fee amount to effectively use float point calculations.
function setAbacusFee(uint _abacusFeeMul1000) external onlyOwner() {
    require(_abacusFeeMul1000>=0 && _abacusFeeMul1000<MAX_ABACUS_FEE_MUL_1000, "!fee<max");
    abacusFeeMul1000=_abacusFeeMul1000;
    /// @dev NOTICE! If you change the abacus fee, it does not change the custom abacus fees, so you must change those separately. This is to avoid large gas fees from looping through lists.
}

/// @notice Function to set a custom abacus fee for specific wallet
function setCustomAbacusFeeForEOA(address _address, address _token, uint _customFeeMul1000) external onlyOwner() {
    require(_customFeeMul1000<=MAX_ABACUS_FEE_MUL_1000);
    addressToCustomFee[_address][_token] =_customFeeMul1000;
}

/// @notice Function to set a custom abacus fee for specific wallet
function removeCustomAbacusFeeFromEOA(address _address, address _token) external onlyOwner() {
    delete addressToCustomFee[_address][_token];
}

/// @notice Function to withdraw profits in native tokens from the contract.
/// @notice It is important to mention that this has no effect on the operability of the contract. Even if there is a contract balance of zero, the contract still functions normally, allowing for completely trustless swaps. 
function withdrawAbacusProfits(address _to, uint _amount) external onlyOwner() {
    require(_amount<=address(this).balance, "amt>bal");
    SafeTransferLib.safeTransferETH(_to, _amount);
}

/// @notice Function to transfer ownership of the Abacus contract.
function transferOwnership(address _newOwner) external onlyOwner() {
    _owner=_newOwner;
}


/// @notice TODO: Check approved
function checkApproved(address _token, uint _amount)external view returns (bool) {
    uint256 amount = ERC20(_token).allowance(_token,address(this));
    if (amount < _amount) {
        return false;
    }else{
        return true;
    }
} 

/// @notice approve all swap routers
function approveAllSwapRouters(address _token, uint _amount) private {
    approveUniV2Router(_token, _amount);
    approveUniV3Router(_token, _amount);
}

/// @notice approve univ2 router
function approveUniV2Router(address _token, uint _amount) private {
    ERC20(_token).approve(uniV2RouterAddress, _amount);
}

/// @notice approve univ3 router
function approveUniV3Router(address _token, uint _amount) private {
    ERC20(_token).approve(uniV3RouterAddress, _amount);
}





/// @notice Function to calculate fixed point multiplication (from RariCapital/Solmate)
function mulDiv(uint256 x,uint256 y,uint256 denominator) internal pure returns (uint256 z) {
    assembly {
        // Store x * y in z for now.
        z := mul(x, y)

        // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
        if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
            revert(0, 0)
        }

        // Divide z by the denominator.
        z := div(z, denominator)
    }
}




/// @dev FIXME: delete later, just for debugging

function toString(address account) public pure returns(string memory) {
    return toString(abi.encodePacked(account));
}

function toString(uint256 value) public pure returns(string memory) {
    return toString(abi.encodePacked(value));
}

function toString(bytes32 value) public pure returns(string memory) {
    return toString(abi.encodePacked(value));
}

function toString(bytes memory data) public pure returns(string memory) {
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(2 + data.length * 2);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < data.length; i++) {
        str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
        str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
    }
    return string(str);
}

   
}

