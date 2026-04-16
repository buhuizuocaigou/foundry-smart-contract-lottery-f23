//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console2} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;
    // error Raffle__NotEnoughEthSent();
    // error Raffle__RaffleNotOpen();

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
    // function enterRaffle() external payable {
    //     //注意 没参数括号内也不能生
    //     if (msg.value < i_entranceFee) revert Raffle__NotEnoughEthSent(); //做回滚的测试
    //     //如果这个发送的函数的值比 我自己抽奖的那个人要小的话  快速回滚这个数值到相当于是 即将运行的那个合约根本没啥钱
    //     if (s_raffleState != RaffleState.OPEN) revert Raffle__RaffleNotOpen(); //做数据回滚操作，并且状态回滚 但是我们需要验证这个回滚到底饭没发生于是乎就出现了这个我们要借助一个vm.expectRevert

    //     s_players.push(payable(msg.sender)); //推送抽奖者到这个数组内
    //     emit EnteredRaffle(msg.sender); //设置emit 的是为了将链内的事件同步到链外去做，并且这个事件不写入一个storage内
    // }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        vm.prank(PLAYER); //借助player 这个身份

        vm.expectRevert(Raffle.Raffle__NotEnoughETHEntered.selector); //看看到底有没有回滚 .selector是意味着evmYOGN 用字节表现错误的那种机制代码 evm只认字节 而 .selector是将他编译成字节的模型 这样子能让EVM底层认识到这个
        raffle.enterRaffle();
    }
}
