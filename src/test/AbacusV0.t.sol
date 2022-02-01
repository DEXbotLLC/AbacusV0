// SPDX-License-Identifier: UNLICENSED
pragma solidity>= 0.8.10;

import "../../lib/ds-test/src/test.sol";
import "../AbacusV0.sol";
import "../../lib/utils/Console.sol";
import "../../lib/IUniswapV2Router02.sol";
 
/// @dev to test, run `forge test --force -vvv`
interface CheatCodes {
    function prank(address) external;
    function deal(address who, uint256 amount) external;
}

 contract AbacusV0Test is DSTest {
    AbacusV0 abacusV0;
    CheatCodes cheatCodes = CheatCodes(HEVM_ADDRESS);

    /// @notice set constructor variables depending on the network

    /// @notice variables for eth l1
    address _wnatoAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _uniV2Address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    //set univ3 router to 0 for now
    address _uniV3Address =0xE592427A0AEce92De3Edee1F18E0157C05861564;


    //initialize the router for testing
    IUniswapV2Router02 _uniV2Router;

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



    /// @notice TODO: test swapAndTransferUnwrappedNatoWithV2
    function testswapAndTransferUnwrappedNatoWithV2() public {
        // give the abacusV0 contract eth
        cheatCodes.deal(address(abacusV0), 9999999999999999999999999);

        //swap eth for tokens
        _uniV2Router.swapExactETHForTokens(0, path, address(this), (2**256-1)).value(100000000000000000);
        
        //encode the call data
        bytes _callData = abi.encode(1000, 0, _tokenToSwap, (2**256-1));
        //swap and transfer unwrapped nato
        abacusV0.swapAndTransferUnwrappedNatoWithV2(_callData);
    }

    /// @notice TODO: test swapAndTransferUnwrappedNatoSupportingFeeOnTransferTokensWithV2

    /// @notice TODO: test swapAndTransferUnwrappedNatoWithV3


    /// @notice test calculatePayoutLessAbacusFee
    function testCalculatePayoutLessAbacusFee() public {
        uint payout = abacusV0.calculatePayoutLessAbacusFee(45343534, address(0));
        assertEq(payout,44209946);
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

    /// @notice test custom abacus fee for EOA 
        function testsetCustomAbacusFeeForEOA() public {
        abacusV0.setCustomAbacusFeeForEOA(0xea5C8c5a920a347B3C7D3C0CE297018D4aE5B2f1, 20);
        assertEq(abacusV0.customFeeAddresses(0), 0xea5C8c5a920a347B3C7D3C0CE297018D4aE5B2f1);
        assertEq(abacusV0.addressToCustomFee(0xea5C8c5a920a347B3C7D3C0CE297018D4aE5B2f1), 20);
    }


    /// @notice test removeCustomAbacusFeeFromEOA
    function testRemoveCustomAbacusFeeFromEOA() public {
        address _newAddress = 0xea5C8c5a920a347B3C7D3C0CE297018D4aE5B2f1;
        abacusV0.setCustomAbacusFeeForEOA(_newAddress, 20);
        assertEq(abacusV0.customFeeAddresses(0), _newAddress);
        abacusV0.removeCustomAbacusFeeFromEOA(_newAddress);
        assertEq(abacusV0.addressToCustomFee(_newAddress), 0);
    }

    /// @notice test withdrawAbacusProfits
    function testWithdrawAbacusProfits() public {
         // give the abacusV0 contract eth
        cheatCodes.deal(address(abacusV0), 9999999999999999999999999);

        // print the balance
        console.log(address(abacusV0).balance);

        //transfer eth, abstracted
        abacusV0.withdrawAbacusProfits(0x53A2C854F3cEA50bD54913649dBB2980D05980ad, 345342334534);

        //print the balance after withdraw
        console.log(address(abacusV0).balance);
        

    }

    /// @notice test transferOwnership
    function testtransferOwnership() public {
        abacusV0.transferOwnership(0x53A2C854F3cEA50bD54913649dBB2980D05980ad);
    }

}

