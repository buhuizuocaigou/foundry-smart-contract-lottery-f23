//SPDX:License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

abstract contract CodeConstants {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

//生成 raffle.sol这些初始化的参数结构有了生成部分内容下面进行本地网络配置不评分

contract HelperConfig is Script, CodeConstants {
    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator; //继承的代码部分构造函数  因为之前借助了VRF的继承代码 所以必须这么做
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
    } //这里对应上了Raffle.sol的constructor 部分内容想当于是提供初始化的参数的部分
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether, //多少个eth参与抽奖
                interval: 30, //多少秒一轮
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B, //官方为了获取随机数地址借助调用chaink的
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, //是chainklink文档给的调用了那个gas档位
                callbackGasLimit: 500000, //这里是毁掉的gas额度
                subscriptionId: 0
            }); //这里对上了之前的上面struct的配置 一一对应 具体chainklink的链接：https://docs.chain.link/vrf/v2-5/supported-networks
    }
    //这是类似于anvil生成的本地链
    function getlocalConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether, //多少个eth参与抽奖
                interval: 30, //多少秒一轮
                vrfCoordinator: address(0), //官方为了获取随机数地址借助调用chaink的
                gasLane: bytes32(0), //是chainklink文档给的调用了那个gas档位
                callbackGasLimit: 500000, //这里是毁掉的gas额度
                subscriptionId: 0
            });
    }

    function getConfigByChainId(
        uint256 chainId
    ) public view returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
            //如果这个chainid  的配置不是0地址 证明配置已经存在了 直接返回
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
            //如果是本地链 现场部署mork合约
        } else {
            //如果这俩都不是直接回滚
            revert HelperConfig__InvalidChainId();
        }
    }
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        //检查 如果 活动的玩过 不是0的话返回本地的值
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            //如果不等于0的话证明已经有了 相当于之前已经部署过了
            return localNetworkConfig;
        }
    }
}
