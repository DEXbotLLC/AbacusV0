// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.10;

import "../../lib/ds-test/src/test.sol";
import "../AbacusV0.sol";
import "../../lib/utils/Console.sol";
import "../../lib/IUniswapV2Router02.sol";
import "../../lib/IUniswapV2Factory.sol";

import "../../lib/ERC20.sol";
import "../../lib/utils/Console.sol";

/// @dev to test, run `forge test --force -vvv`
interface CheatCodes {
    function prank(address) external;

    function deal(address who, uint256 amount) external;
}

contract DEXbotAbacusV0Test is DSTest {
    DEXbotAbacusV0 abacusV0;
    CheatCodes cheatCodes = CheatCodes(HEVM_ADDRESS);
    uint256 constant MAX_UINT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    receive() external payable {}

    fallback() external payable {}

    /// @notice set constructor variables depending on the network
    /// @notice variables for eth l1
    address _wnatoAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _uniV2Address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address _uniV2FactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    //initialize the router for testing
    IUniswapV2Router02 _uniV2Router;
    //initialize the univ2factory
    IUniswapV2Factory _uniV2Factory;
    //address for testing swaps
    address swapToken = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    //address for testing swaps with fees on transfer
    address swapTokenFeeOnTransfer = 0x8B3192f5eEBD8579568A2Ed41E6FEB402f93f73F;

    function setUp() public {
        abacusV0 = new DEXbotAbacusV0(_wnatoAddress);
        _uniV2Router = IUniswapV2Router02(_uniV2Address);
        _uniV2Factory = IUniswapV2Factory(_uniV2FactoryAddress);
    }

    /// @notice test public variables
    function testPublicVariables() public {
        //test the wnato address
        assertEq(abacusV0.wnatoAddress(), _wnatoAddress);
        //test the abacus fee set in the contstructor
        assertEq(abacusV0.ABACUS_FEE_MUL_1000(), 25);
    }

    /// @notice test swapExactTokensForTokens baseline
    function testSwapExactTokensForTokensBaseline() public {
        // give the abacusV0 contract eth
        cheatCodes.deal(address(this), 9999999999999999999999999);

        //set the path
        address[] memory path = new address[](2);
        path[0] = _wnatoAddress;
        path[1] = swapToken;

        // swap eth for tokens
        _uniV2Router.swapExactETHForTokens{value: 1000000000000000000}(
            1,
            path,
            address(this),
            (2**256 - 1)
        );

        //approve the abacusV0 to interact with the swapToken
        ERC20(swapToken).approve(address(_uniV2Address), (2**256 - 1));

        address lp = _uniV2Factory.getPair(swapToken, _wnatoAddress);

        uint256 amountIn = mulDiv(
            ERC20(swapToken).balanceOf(address(this)),
            25,
            100
        );

        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(lp)
            .getReserves();

        //calculate the amountOut
        uint256 amountOut = abacusV0.getAmountOut(amountIn, reserve0, reserve1);

        //set the path
        address[] memory swapPath = new address[](2);
        swapPath[0] = swapToken;
        swapPath[1] = _wnatoAddress;

        IUniswapV2Router02(_uniV2Address).swapExactTokensForTokens(
            amountIn,
            amountOut,
            swapPath,
            msg.sender,
            (2**256 - 1)
        );

        //calculate the gas cost of call data
        bytes memory callData = abi.encode(
            amountIn,
            amountOut,
            swapPath,
            msg.sender,
            (2**256 - 1)
        );
        console.logBytes(callData);
        console.log(calculateCallDataGasCost(callData));
    }

    /// @notice test swapExactTokensForTokens baseline
    function testSwapExactTokensForETHBaseline() public {
        // give the abacusV0 contract eth
        cheatCodes.deal(address(this), 9999999999999999999999999);

        //set the path
        address[] memory path = new address[](2);
        path[0] = _wnatoAddress;
        path[1] = swapToken;

        // swap eth for tokens
        _uniV2Router.swapExactETHForTokens{value: 1000000000000000000}(
            1,
            path,
            address(this),
            (2**256 - 1)
        );

        //approve the abacusV0 to interact with the swapToken
        ERC20(swapToken).approve(address(_uniV2Address), (2**256 - 1));

        address lp = _uniV2Factory.getPair(swapToken, _wnatoAddress);

        uint256 amountIn = mulDiv(
            ERC20(swapToken).balanceOf(address(this)),
            25,
            100
        );

        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(lp)
            .getReserves();

        //calculate the amountOut
        uint256 amountOut = abacusV0.getAmountOut(amountIn, reserve0, reserve1);

        //set the path
        address[] memory swapPath = new address[](2);
        swapPath[0] = swapToken;
        swapPath[1] = _wnatoAddress;

        IUniswapV2Router02(_uniV2Address).swapExactTokensForETH(
            amountIn,
            amountOut,
            swapPath,
            msg.sender,
            (2**256 - 1)
        );

        //calculate the gas cost of call data
        bytes memory callData = abi.encode(
            amountIn,
            amountOut,
            swapPath,
            msg.sender,
            (2**256 - 1)
        );
        console.logBytes(callData);
        console.log(calculateCallDataGasCost(callData));
    }

    /// @notice test swap
    function testSwapExactTokensForTokensSupportingFeeOnTransferTokensBaseline()
        public
    {
        // give the abacusV0 contract eth
        cheatCodes.deal(address(this), 9999999999999999999999999);

        //set the path
        address[] memory path = new address[](2);
        path[0] = _wnatoAddress;
        path[1] = swapToken;

        // swap eth for tokens
        _uniV2Router.swapExactETHForTokens{value: 1000000000000000000}(
            1,
            path,
            address(this),
            (2**256 - 1)
        );

        //approve the abacusV0 to interact with the swapToken
        ERC20(swapToken).approve(address(_uniV2Address), (2**256 - 1));

        address lp = _uniV2Factory.getPair(swapToken, _wnatoAddress);

        uint256 amountIn = mulDiv(
            ERC20(swapToken).balanceOf(address(this)),
            25,
            100
        );

        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(lp)
            .getReserves();

        //calculate the amountOut
        uint256 amountOut = abacusV0.getAmountOut(amountIn, reserve0, reserve1);

        //set the path
        address[] memory swapPath = new address[](2);
        swapPath[0] = swapToken;
        swapPath[1] = _wnatoAddress;

        IUniswapV2Router02(_uniV2Address)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountIn,
                amountOut,
                swapPath,
                msg.sender,
                (2**256 - 1)
            );
    }

    /// @notice test swapAndTransferUnwrappedNatoWithV2
    function testSwapAndTransferUnwrappedNatoWithV2() public {
        // give the abacusV0 contract eth
        cheatCodes.deal(address(this), 9999999999999999999999999);

        //set the path
        address[] memory path = new address[](2);
        path[0] = _wnatoAddress;
        path[1] = swapToken;

        // swap eth for tokens
        _uniV2Router.swapExactETHForTokens{value: 1000000000000000000}(
            1,
            path,
            address(this),
            (2**256 - 1)
        );

        //approve the abacusV0 to interact with the swapToken
        ERC20(swapToken).approve(address(abacusV0), (2**256 - 1));

        address lp = _uniV2Factory.getPair(swapToken, _wnatoAddress);

        uint256 amountIn = mulDiv(
            ERC20(swapToken).balanceOf(address(this)),
            25,
            100
        );

        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(lp)
            .getReserves();

        //calculate the amountOut
        uint256 amountOut = abacusV0.getAmountOut(amountIn, reserve0, reserve1);

        // swap and transfer unwrapped nato
        abacusV0.swapAndTransferUnwrappedNatoWithV2(
            lp,
            amountIn,
            amountOut,
            swapToken,
            false
        );

        //calculate the gas cost of call data
        bytes memory callData = abi.encode(
            lp,
            amountIn,
            amountOut,
            swapToken,
            false
        );
        console.logBytes(callData);
        console.log(calculateCallDataGasCost(callData));
    }

    /// @notice test swapAndTransferUnwrappedNatoWithV2
    function testSwapAndTransferUnwrappedNatoSupportingFeeOnTransferTokensWithV2()
        public
    {
        // give the abacusV0 contract eth
        cheatCodes.deal(address(this), 9999999999999999999999999);

        //set the path
        address[] memory path = new address[](2);
        path[0] = _wnatoAddress;
        path[1] = swapToken;

        // swap eth for tokens
        _uniV2Router.swapExactETHForTokens{value: 1000000000000000000}(
            1,
            path,
            address(this),
            (2**256 - 1)
        );

        //approve the abacusV0 to interact with the swapToken
        ERC20(swapToken).approve(address(abacusV0), (2**256 - 1));

        address lp = _uniV2Factory.getPair(swapToken, _wnatoAddress);

        uint256 amountIn = mulDiv(
            ERC20(swapToken).balanceOf(address(this)),
            25,
            100
        );

        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(lp)
            .getReserves();

        //calculate the amountOut
        uint256 amountOut = abacusV0.getAmountOut(amountIn, reserve0, reserve1);

        // swap and transfer unwrapped nato
        abacusV0
            .swapAndTransferUnwrappedNatoSupportingFeeOnTransferTokensWithV2(
                lp,
                amountIn,
                amountOut,
                swapToken,
                false
            );
    }

    /// @notice test calculatePayoutLessAbacusFee
    function testCalculatePayoutLessAbacusFee(uint256 _amountIn) public {
        /// @notice amountIn can not be greater than the following number because it causes the mulDiv function to overflow when calculating x * y
        /// @notice the tx will revert if the input is greater than this number
        if ((_amountIn * 25) / _amountIn == 25) {
            uint256 payout = abacusV0.calculatePayoutLessAbacusFee(
                _amountIn,
                address(0),
                false
            );
            assertEq(payout, (_amountIn - mulDiv(_amountIn, 25, 1000)));
        }
    }

    function testCalculatePayoutLessAbacusFeeWithCustomFee(
        uint256 _amountIn,
        uint256 _customFee
    ) public {
        if (((_amountIn * _customFee) / _amountIn == _customFee)) {
            if (_customFee <= 100 && _customFee > 0) {
                abacusV0.setCustomAbacusFeeForEOA(
                    address(this),
                    0x514910771AF9Ca656af840dff83E8264EcF986CA,
                    _customFee
                );
                uint256 payout = abacusV0.calculatePayoutLessAbacusFee(
                    _amountIn,
                    0x514910771AF9Ca656af840dff83E8264EcF986CA,
                    true
                );
                console.log(payout);
                assertEq(
                    payout,
                    _amountIn - (mulDiv(_amountIn, _customFee, 1000))
                );
            }
        }
    }

    /// @notice test custom abacus fee for EOA
    function testSetCustomAbacusFeeForEOA() public {
        abacusV0.setCustomAbacusFeeForEOA(
            address(this),
            0x514910771AF9Ca656af840dff83E8264EcF986CA,
            20
        );
        assertEq(
            abacusV0.customFees(
                abi.encode(
                    address(this),
                    0x514910771AF9Ca656af840dff83E8264EcF986CA
                )
            ),
            20
        );
    }

    /// @notice test checkForCustomFee
    function testCheckForCustomFee() public {
        abacusV0.setCustomAbacusFeeForEOA(
            address(this),
            0x514910771AF9Ca656af840dff83E8264EcF986CA,
            10
        );

        bool customFeeCheck = abacusV0.checkForCustomFee(
            address(this),
            0x514910771AF9Ca656af840dff83E8264EcF986CA
        );

        //check that the custom fee check is true
        assertTrue(customFeeCheck);
    }

    /// @notice test checkForCustomFee
    function testFailCheckForCustomFee() public {
        bool customFeeCheck = abacusV0.checkForCustomFee(
            address(this),
            0x514910771AF9Ca656af840dff83E8264EcF986CA
        );

        //check that the custom fee check is true
        assertTrue(customFeeCheck);
    }

    /// @notice test removeCustomAbacusFeeFromEOA
    function testRemoveCustomAbacusFeeFromEOA() public {
        address _newAddress = address(this);
        abacusV0.setCustomAbacusFeeForEOA(
            _newAddress,
            0x514910771AF9Ca656af840dff83E8264EcF986CA,
            20
        );
        abacusV0.removeCustomAbacusFeeFromEOA(
            _newAddress,
            0x514910771AF9Ca656af840dff83E8264EcF986CA
        );
        assertEq(
            abacusV0.customFees(
                abi.encode(
                    _newAddress,
                    0x514910771AF9Ca656af840dff83E8264EcF986CA
                )
            ),
            0
        );
    }

    /// @notice test onlyOwner Modifier
    function testFailOnlyOwner() public {
        cheatCodes.prank(address(0));
        abacusV0.setCustomAbacusFeeForEOA(
            address(this),
            0x514910771AF9Ca656af840dff83E8264EcF986CA,
            20
        );
    }

    /// @notice test withdrawAbacusProfits
    function testWithdrawAbacusProfits() public {
        // give the abacusV0 contract eth
        cheatCodes.deal(address(abacusV0), 9999999999999999999999999);
        //transfer eth, abstracted
        abacusV0.withdrawAbacusProfits(
            0x53A2C854F3cEA50bD54913649dBB2980D05980ad,
            345342334534
        );

        assertEq(address(abacusV0).balance, 9999999999999654657665465);
    }

    /// @notice test transferOwnership
    function testtransferOwnership() public {
        abacusV0.transferOwnership(0x53A2C854F3cEA50bD54913649dBB2980D05980ad);
    }

    /// @notice Function to calculate fixed point multiplication (from RariCapital/Solmate)
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(
                and(
                    iszero(iszero(denominator)),
                    or(iszero(x), eq(div(z, x), y))
                )
            ) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }
}

/// @notice Function to calculate the gas cost of call data
function calculateCallDataGasCost(bytes memory _callData)
    pure
    returns (uint256)
{
    uint256 i = 0;
    uint256 gasCost;
    uint256 callDataLength = _callData.length;

    //For each byte in call data, if it is a 0 byte, add 4 gas. Else, add 68 gas.
    for (i; i < callDataLength; i++) {
        if (_callData[i] == 0) {
            gasCost += 4;
        } else {
            gasCost += 16;
        }
    }

    return gasCost;
}
