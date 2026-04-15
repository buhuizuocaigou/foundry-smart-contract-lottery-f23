//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;
import {DeployRaffle} from "../script/DeployRaffle.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {Test, console2} from "forge-std/Test.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;
    //都是之前传递过来的参数 是Raffle建立抽奖的时候初始化的数字
    address public PLAYER = makeAddr("player"); //建立一个玩家 获取他的地址
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        //这个设立一个新的deploy 的内容
        (raffle, helperConfig) = deployer.run();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
        //伪装成 player身份去做借助player调用
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
    }
    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        //为啥在子合约中重写呢？因为VRFConsumerBaseV2Plus被标记为 virtual 需要在自合约中重写
    }
}
