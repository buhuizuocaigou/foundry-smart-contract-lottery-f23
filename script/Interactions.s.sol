// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {
    VRFCoordinatorV2_5Mock
} from "@chainlink/contracts@1.5.0/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

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

    //我们需要构造一个 Fundsubsctipton 函数来后才能夯实构造并且 人为的mock 一些代币给他 目的是能mock出在本地模拟出link 的交易合约
}
contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; //往anvil搭建的本地中充值3个eth  因为不是主网 且不上链条所以可能有这个烦恼在身上

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().linkToken;
        fundSubscription(vrfCoordinator, subscriptionId, linkToken);
    }

    function run() external {
        fundSubscriptionUsingConfig();
    } //与创建订阅中的所列出的结构以及啥非常相似 ,但是我们因为是本地链且需要引入link合约所以的话我们在这也得如法炮制 ，只不过这一切是自己的
    //我们需要啥：
    //1 测试网部署了link 我们能够访问地址
    //2. anvil本身并没有预制 link合约，且我们需要部署模拟的link代币合约

    //经典进行分离 以方便管理 这个在
    //搞定配置 ，然后上链
    //这里 helperconfig 搞定“值从哪里来”
    //fundSubscriptionUsingConfig解决怎么把值取出来
    //fundSubscription解决拿到了以后干嘛
    function fundSubscription(
        address vrfCoordinator,
        uint256 subscriptionId,
        address linkToken
    ) public {
        if (block.chainid == ETH_ANVIL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subscriptionId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            console.log(LinkToken(linkToken).balanceOf(msg.sender));
            console.log(msg.sender);
            console.log(LinkToken(linkToken).balanceOf(address(this)));
            console.log(address(this));
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
            vm.stopBroadcast();
        }
    }
}
