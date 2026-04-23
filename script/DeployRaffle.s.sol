// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 写这个文件的目的就是通过不同的chainid进行筛选器的过程，进行自动筛选，筛选标准是通过chainid进行的
import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {
    CreateSubscription,
    FundSubscription,
    AddConsumer
} from "./Interactions.s.sol"; // fix: 去掉重复的单独 import

contract DeployRaffle is Script {
    // run() 是 foundry 的固定入口，forge script 调用它
    function run() external returns (Raffle, HelperConfig) {
        return deployContract();
    }

    // deployContract 是真正的部署逻辑，最终把 Raffle 和 HelperConfig 返回出去
    function deployContract() internal returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // subscriptionId == 0 说明是本地 Anvil 环境，需要自动创建并充值订阅
        if (config.subscriptionId == 0) {
            // 第一步：创建订阅，createSubscription 只接收 vrfCoordinator 一个参数
            // fix: 去掉多余的 config.subscriptionId 和 config.linkToken 参数
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, ) = createSubscription.createSubscription(
                config.vrfCoordinator
            );

            // 第二步：给订阅充值 LINK，有了 subId 才能充值
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinator,
                config.subscriptionId,
                config.linkToken
            );
        }

        // 部署 Raffle 主合约
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        // 第三步：把刚部署的 Raffle 注册为 VRF 消费者白名单
        // 必须在 stopBroadcast 之后做，地址已经确定
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(raffle),
            config.vrfCoordinator,
            config.subscriptionId
        );

        return (raffle, helperConfig);
    }
}
