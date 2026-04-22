// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {
    VRFCoordinatorV2_5Mock
} from "@chainlink/contracts@1.5.0/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscription is Script {
    function CreateSubscriptionUsingConfig() public returns (uint64) {}

    function run() external returns (uint64) {
        //本质是将启动项进行封装管理的操作类型
        return CreateSubscriptionUsingConfig();
    }
    //写这个函数的目的是创建订阅 的目的
    function createSubscription(
        address VRFCoordinator
    ) public returns (uint256) {
        console.log("Creating subscription on chianlinkid is :", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(VRFCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console.log("you id is", subId);
        console.log("Please update subscriptionID IN HelpConfig");
        return subId;
    }
    //新版本的V2——5 是 把subID从uint64 升级到了uint256 需要注意一下
}
