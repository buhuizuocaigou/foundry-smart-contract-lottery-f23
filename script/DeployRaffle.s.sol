//SPDX:License-Identifier: MIT
pragma solidity ^0.8.20;
//写这个文件的目的就是通过不同的chainid进行筛选器的过程。进行自动筛选 他筛选的标准是通过chainid进行的。
import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription} from "./Interactions.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        return deployContract();
    }
    //这个run函数存在是foundry的固定入口  forge script是调用他的然后deployContract 这个是真正的部署逻辑 把最终部署的内容回馈给Raffle 跟 HelperConfig
    function deployContract() internal returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); //调用mock计划的东西

        //如何筛选呢返回的值要实例化上报到 Raffle 跟HelpConfig上面
        //那么如何部署这些合约呢？我们要参数 Raffle的 比如 ：entranceFee interval等等包括gaslane 这些东西是随着不同的区块链他的内容不同 那么我们该如何处理呢？如何让他适配呢？答案是写一个helpconfig 根据不同的部署网络也就是blockchainlink的值来制定这些内容
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            config.subscriptionId = createSubscription.createSubscription(
                config.vrfCoordinator
            );
        }
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
        return (raffle, helperConfig);
    }
}
