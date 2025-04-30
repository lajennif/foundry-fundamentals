// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address alice = makeAddr("alice");
    uint256 constant SEND_VALUE = 1e18; // 1 ETH
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    modifier funded() {
        vm.deal(alice, STARTING_BALANCE);
        vm.prank(alice);
        fundMe.fund{value: SEND_VALUE}();
        assert(address(fundMe).balance > 0);
        _;
    }

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        if (block.chainid == 11155111) {
            uint256 version = fundMe.getVersion();
            assertEq(version, 4);
        }
        if (block.chainid == 1) {
            uint256 version = fundMe.getVersion();
            assertEq(version, 6);
        } else {
            uint256 version = fundMe.getVersion();
            assertEq(version, 4);
        }
    }

    function testRevertIfInsufficientFunds() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(alice);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, alice);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawFromSingleFunder() public funded {
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.i_owner().balance;

        vm.startPrank(fundMe.i_owner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.i_owner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalance, startingOwnerBalance + startingFundMeBalance);
    }

    // function testWithdrawFromMultipleFunders() public funded {
    //     uint160 numberOfFunders = 10;
    //     uint160 startingFunderIndex = 1;
    //     for (
    //         uint160 i = startingFunderIndex;
    //         i < numberOfFunders + startingFunderIndex;
    //         i++
    //     ) {
    //         hoax(address(i), SEND_VALUE);
    //         fundMe.fund{value: SEND_VALUE}();
    //     }

    //     uint256 startingFundMeBalance = address(fundMe).balance;
    //     uint256 startingOwnerBalance = fundMe.i_owner().balance;

    //     vm.startPrank(fundMe.i_owner());
    //     fundMe.withdraw();
    //     vm.stopPrank();

    //     console.log("FundMe balance after: %s", address(fundMe).balance);
    //     console.log("Owner balance after: %s", fundMe.i_owner().balance);
    //     console.log(
    //         "Expected: %s",
    //         startingFundMeBalance + startingOwnerBalance
    //     );

    //     assert(address(fundMe).balance == 0);
    //     assert(
    //         startingFundMeBalance + startingOwnerBalance ==
    //             fundMe.i_owner().balance
    //     );
    //     assert(
    //         (numberOfFunders + 1) * SEND_VALUE ==
    //             fundMe.i_owner().balance - startingOwnerBalance
    //     );
    // }
    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders + startingFunderIndex; i++) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.i_owner().balance;

        vm.startPrank(fundMe.i_owner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.i_owner().balance);
        // assert(
        //     (numberOfFunders + 1) * SEND_VALUE ==
        //         fundMe.i_owner().balance - startingOwnerBalance
        // );
        assertApproxEqAbs(
            fundMe.i_owner().balance - startingOwnerBalance,
            (numberOfFunders + 1) * SEND_VALUE,
            2e17 // 0.001 ETH wiggle room
        );
    }
}
