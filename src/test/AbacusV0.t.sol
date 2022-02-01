// SPDX-License-Identifier: UNLICENSED
pragma solidity>= 0.8.10;

import "../../lib/ds-test/src/test.sol";
import "../AbacusV0.sol";
import "./Console.sol";


/// @dev to test, run `forge test --force -vvv`

contract User {

}

contract AbacusV0Test is DSTest {
    AbacusV0 abacusV0;
    User user;


    /// @notice set constructor variables depending on the network

    /// @notice variables for eth l1
    address _wnatoAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _uniV2Address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    //set univ3 router to 0 for now
    address _uniV3Address =address(0) ;



    function setUp() public {
        abacusV0= new AbacusV0(_wnatoAddress, _uniV2Address, _uniV3Address);
        user= new User();
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


    /// @notice test setAbacusFee
    function testSetAbacusFee() public {
        abacusV0.setAbacusFee(25);
    }


    // /// @notice test fail setAbacusFee with not owner as sender
    // function testFailSetAbacusFee() public {
    // }

    /// @notice test custom abacus fee for EOA
        function testsetCustomAbacusFeeForEOA() public {
        abacusV0.setCustomAbacusFeeForEOA(0xea5C8c5a920a347B3C7D3C0CE297018D4aE5B2f1, 20);
        assertEq(abacusV0.customFeeAddresses(0), 0xea5C8c5a920a347B3C7D3C0CE297018D4aE5B2f1);
        assertEq(abacusV0.addressToCustomFee(0xea5C8c5a920a347B3C7D3C0CE297018D4aE5B2f1), 20);
    }


    // /// @notice test fail testsetCustomAbacusFeeForEOA 
    // function testFailSetCustomAbacusFeeForEOA() public {
    //     abacusV0.setCustomAbacusFeeForEOA(0xea5C8c5a920a347B3C7D3C0CE297018D4aE5B2f1, 20);
    //     assertEq(abacusV0.customFeeAddresses(0), 0xea5C8c5a920a347B3C7D3C0CE297018D4aE5B2f1);
    //     assertEq(abacusV0.addressToCustomFee(0xea5C8c5a920a347B3C7D3C0CE297018D4aE5B2f1), 20);
    // }

    function testCalculatePayoutLessAbacusFee() public {
        abacusV0.calculatePayoutLessAbacusFee(100000, address(0));

    }



}

