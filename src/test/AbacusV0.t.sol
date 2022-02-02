// SPDX-License-Identifier: UNLICENSED
pragma solidity>= 0.8.10;

import "../../lib/ds-test/src/test.sol";
import "../AbacusV0.sol";
import "../../lib/utils/Console.sol";
import "../../lib/IUniswapV2Router02.sol";
import "../../lib/ERC20.sol";
import "../../lib/utils/Console.sol";
 
/// @dev to test, run `forge test --force -vvv`
interface CheatCodes {
    function prank(address) external;
    function deal(address who, uint256 amount) external;
}

 contract AbacusV0Test is DSTest {
    AbacusV0 abacusV0;
    CheatCodes cheatCodes = CheatCodes(HEVM_ADDRESS);

    receive() external payable {
    }

    fallback() external payable {
    }


    /// @notice set constructor variables depending on the network
    /// @notice variables for eth l1
    address _wnatoAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _uniV2Address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address _uniV3Address = 0xE592427A0AEce92De3Edee1F18E0157C05861564;


    //initialize the router for testing
    IUniswapV2Router02 _uniV2Router;

    //address for testing swaps
    address swapToken = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    //address for testing swaps with fees on transfer
    address swapTokenFeeOnTransfer = 0x514910771AF9Ca656af840dff83E8264EcF986CA;


    function setUp() public {
         abacusV0 = new AbacusV0(_wnatoAddress, _uniV2Address, _uniV3Address);
         _uniV2Router=IUniswapV2Router02(_uniV2Address);
    }

    /// @notice test public variables
    function testPublicVariables() public {
        //test the wnato address
        assertEq(abacusV0.wnatoAddress(), address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
        //test the abacus fee set in the contstructor
        assertEq(abacusV0.abacusFeeMul1000(), 25);
        //test the univ2 address
        assertEq(abacusV0.uniV2RouterAddress(), _uniV2Address);
         //test the univ3 address
        assertEq(abacusV0.uniV3RouterAddress(), _uniV3Address);
    }



    /// @notice test swapAndTransferUnwrappedNatoWithV2
    function testApproveSwapAndTransferUnwrappedNatoWithV2() public {
        // give the abacusV0 contract eth
        cheatCodes.deal(address(this), 9999999999999999999999999);

        //set the path
        address[] memory path = new address[](2);
        path[0]=_wnatoAddress;
        path[1]= swapToken;

        // swap eth for tokens
        _uniV2Router.swapExactETHForTokens{value: 1000000000000000000}(1, path, address(this), (2**256-1));

        //approve the abacusV0 to interact with the swapToken
        ERC20(swapToken).approve(address(abacusV0), (2**256-1));
        

        //encode the call data
        bytes memory _callData = abi.encode(10000000000, 1, swapToken, (2**256-1));

        // swap and transfer unwrapped nato
        abacusV0.approveSwapAndTransferUnwrappedNatoWithV2(_callData);
    }


    // /// @notice TODO: test swapAndTransferUnwrappedNatoSupportingFeeOnTransferTokensWithV2
    // function testApproveSwapAndTransferUnwrappedNatoSupportingFeeOnTransferTokensWithV2() public {
    //     // give the abacusV0 contract eth
    //     cheatCodes.deal(address(this), 9999999999999999999999999);

    //     //set the path
    //     address[] memory path = new address[](2);
    //     path[0]=_wnatoAddress;
    //     path[1]= swapToken;

    //     // swap eth for tokens
    //     _uniV2Router.swapExactETHForTokens{value: 1000000000000000000}(1, path, address(this), (2**256-1));

    //     //approve the abacusV0 to interact with the swapToken
    //     ERC20(swapToken).approve(address(abacusV0), (2**256-1));
        

    //     //encode the call data
    //     bytes memory _callData = abi.encode(10000000000, 1, swapToken, (2**256-1));

    //     // swap and transfer unwrapped nato
    //     abacusV0.approveSwapAndTransferUnwrappedNatoSupportingFeeOnTransferTokensWithV2(_callData);
    // }


    /// @notice TODO: test swapAndTransferUnwrappedNatoWithV3

    /// @notice TODO: test swapAndTransferUnwrappedNatoSupportingFeeOnTransferTokensWithV2
    function testApproveSwapAndTransferUnwrappedNatoWithV3() public {
        // give the abacusV0 contract eth
        cheatCodes.deal(address(this), 9999999999999999999999999);

        //set the path
        address[] memory path = new address[](2);
        path[0]=_wnatoAddress;
        path[1]= swapToken;

        // swap eth for tokens
        _uniV2Router.swapExactETHForTokens{value: 1000000000000000000}(1, path, address(this), (2**256-1));

        //approve the abacusV0 to interact with the swapToken
        ERC20(swapToken).approve(address(abacusV0), (2**256-1));
        

        //encode the call data, fee is set to .3%
        bytes memory _callData = abi.encode(swapToken, 3000, (2**256-1), 10000000000, 1, 0);


        // swap and transfer unwrapped nato
        abacusV0.approveSwapAndTransferUnwrappedNatoWithV3(_callData);
    }



    /// @notice test calculatePayoutLessAbacusFee
    function testCalculatePayoutLessAbacusFee() public {
        uint payout = abacusV0.calculatePayoutLessAbacusFee(45343534, address(0), address(0));
        assertEq(payout,44209946);
    }

    function testCalculatePayoutLessAbacusFeeWithCustomFee() public {
        abacusV0.setCustomAbacusFeeForEOA(address(this), 0x514910771AF9Ca656af840dff83E8264EcF986CA, 10);
        uint payout = abacusV0.calculatePayoutLessAbacusFee(45343534, address(this), 0x514910771AF9Ca656af840dff83E8264EcF986CA);
        // console.log(payout);
        assertEq(payout, 44890099);
    }

    /// @notice test custom abacus fee for EOA 
        function testsetCustomAbacusFeeForEOA() public {
        abacusV0.setCustomAbacusFeeForEOA(address(this), 0x514910771AF9Ca656af840dff83E8264EcF986CA, 20);
        assertEq(abacusV0.addressToCustomFee(address(this),0x514910771AF9Ca656af840dff83E8264EcF986CA), 20);
    }

    /// @notice test setAbacusFee
    function testSetAbacusFee() public {
        abacusV0.setAbacusFee(26);
        // console.log(abacusV0.abacusFeeMul1000());
    }

    /// @notice test onlyOwner Modifier
    function testFailOnlyOwner() public {
        cheatCodes.prank(address(0));
        abacusV0.setAbacusFee(26);
    }

   

    /// @notice test removeCustomAbacusFeeFromEOA
    function testRemoveCustomAbacusFeeFromEOA() public {
        address _newAddress = address(this);
        abacusV0.setCustomAbacusFeeForEOA(_newAddress, 0x514910771AF9Ca656af840dff83E8264EcF986CA, 20);
        abacusV0.removeCustomAbacusFeeFromEOA(_newAddress, 0x514910771AF9Ca656af840dff83E8264EcF986CA);
        assertEq(abacusV0.addressToCustomFee(_newAddress, 0x514910771AF9Ca656af840dff83E8264EcF986CA), 0);
    }

    /// @notice test withdrawAbacusProfits
    function testWithdrawAbacusProfits() public {
         // give the abacusV0 contract eth
        cheatCodes.deal(address(abacusV0), 9999999999999999999999999);
        //transfer eth, abstracted
        abacusV0.withdrawAbacusProfits(0x53A2C854F3cEA50bD54913649dBB2980D05980ad, 345342334534);

        assertEq(address(abacusV0).balance, 9999999999999654657665465);

    }

    /// @notice test transferOwnership
    function testtransferOwnership() public {
        abacusV0.transferOwnership(0x53A2C854F3cEA50bD54913649dBB2980D05980ad);
    }

}

