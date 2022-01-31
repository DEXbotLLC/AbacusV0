// SPDX-License-Identifier: UNLICENSED
pragma solidity>= 0.8.10;

import "../../lib/ds-test/src/test.sol";
import "../AbacusV0.sol";



contract AbacusV0Test is DSTest {
    AbacusV0 abacusV0;


    //set constructor variables depending on the network
    //variables for eth l1
    address _wnatoAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _uniV2Address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    //set univ3 router to 0 for now
    address _uniV3Address =address(0) ;



    function setUp() public {
        abacusV0= new AbacusV0(_wnatoAddress, _uniV2Address, _uniV3Address);
    }

    function testExample() public {
        assertTrue(true);
    }
}


// contract HelloWorldTest is DSTest {
//     HelloWorld hello;
//     function setUp() public {
//       hello = new HelloWorld("Foundry is fast!");
//     }

//     function test1() public {
//         assertEq(
//             hello.greet(),
//             "Foundry is fast!"
//         );
//     }

//     function test2() public {
//         assertEq(hello.version(), 0);
//         hello.updateGreeting("Hello World");
//         assertEq(hello.version(), 1);
//         assertEq(
//             hello.greet(),
//             "Hello World"
//         );
//     }
// }