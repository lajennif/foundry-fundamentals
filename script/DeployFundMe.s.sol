// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol"; // ✅ Import console
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();
        address sender = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        vm.startBroadcast(sender);
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();

        // ✅ Log the i_owner after deployment
        console.log("Contract deployed at:", address(fundMe));
        console.log("Owner (i_owner) is:", fundMe.i_owner()); // i_owner must be public

        return fundMe;
    }
}
