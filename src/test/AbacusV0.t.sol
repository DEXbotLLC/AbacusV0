// SPDX-License-Identifier: UNLICENSED
pragma solidity>= 0.8.10;

import "../../lib/ds-test/src/test.sol";
import "../AbacusV0.sol";
import "../../lib/utils/Console.sol";
 
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




    function setUp() public {
         abacusV0 = new AbacusV0(_wnatoAddress, _uniV2Address, _uniV3Address);
        // give the test contract eth
        cheatCodes.deal(address(this), 9999999999999999999999999);
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

    /// @notice TODO: test swapAndTransferUnwrappedNatoSupportingFeeOnTransferTokensWithV2

    /// @notice TODO: test swapAndTransferUnwrappedNatoWithV3


    /// @notice test calculatePayoutLessAbacusFee
    function testCalculatePayoutLessAbacusFee() public {
        uint payout = abacusV0.calculatePayoutLessAbacusFee(45343534, address(0));
        assertEq(payout,44209946);
    }


    /// @notice test approveUniV2Router
    function testApproveUniV2Router() public {
        abacusV0.approveUniV2Router(_wnatoAddress, (2**256 - 1));
    }
    /// @notice test approveUniV3Router
    function testApproveUniV3Router() public {
        abacusV0.approveUniV3Router(_wnatoAddress, (2**256 - 1));

    }

    /// @notice test approveAllSwapRouters
    function testApproveAllSwapRouters() public {
        abacusV0.approveAllSwapRouters(_wnatoAddress, (2**256 - 1));
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
 
        // print the balance
        console.log(address(this).balance);
        //transfer eth 
        SafeTransferLib.safeTransferETH(0x53A2C854F3cEA50bD54913649dBB2980D05980ad, 345342334534);
        //print the balance
        console.log(address(this).balance);
        
        // ^^^^ this works

        //transfer eth, abstracted
        abacusV0.withdrawAbacusProfits(0x53A2C854F3cEA50bD54913649dBB2980D05980ad, 345342334534);

        // ^^^^ this fails, error is ETH_TRANSFER_FAILED

    }

    /// @notice test transferOwnership
    function testtransferOwnership() public {
        abacusV0.transferOwnership(0x53A2C854F3cEA50bD54913649dBB2980D05980ad);
    }

}

