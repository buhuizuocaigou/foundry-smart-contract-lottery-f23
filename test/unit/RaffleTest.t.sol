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
    event EnteredRaffle(address indexed player);

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
    //想到如果支付金额不足是否可能被取消的问题：
    function testRaffleRevertsWhenYouDontPayEnough() public {
        vm.prank(PLAYER); //借助player 这个身份

        vm.expectRevert(Raffle.Raffle__NotEnoughETHEntered.selector); //看看到底有没有回滚 .selector是意味着evmYOGN 用字节表现错误的那种机制代码 evm只认字节 而 .selector是将他编译成字节的模型 这样子能让EVM底层认识到这个
        raffle.enterRaffle();
    }
    //测试合约到底是否会如实的像raffle.sol中添加player

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        //Arrage
        vm.prank(PLAYER);

        raffle.enterRaffle{value: entranceFee}(); //以player的身份参与抽奖

        address playerRecorded = raffle.getPlayer(0); //由于有一个用户目的是 获取第一个玩家的地址 数组为0的地址

        assert(playerRecorded == PLAYER); //我预计 这里使用的人是player ，然后如果不是则在我这个失败提示截断
    }
    function testEmitsEventOnEntrance() public {
        vm.prank(PLAYER); //以正常的player身份调用

        vm.expectEmit(true, false, false, false, address(raffle));
        //进行emit测试对比 ，利用这个值 来测试 player的身份跟真事的事件进行对比比较
        //在expectEmit中  其中 1-3对应了indexed在事件中使用的参数，而CheckdATA 对应事件中为任何建立索引的参数，最后 expectEmit期望接受事件的触发地址，素以 只有一个已经家里索引  参数
        emit EnteredRaffle(PLAYER); //先告知我有有一个 index player  然后后后面调用PLAYER真实用户 比较这个伪造的借助事件的 跟 不参与这个事件的是否一致
        raffle.enterRaffle{value: entranceFee}(); //加括号的目的是执行这个函数
    }
}
