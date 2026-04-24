//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console2} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

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
    LinkToken public linkToken;
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
        linkToken = LinkToken(config.linkToken);
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
    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep(""); //检查完时间检查区块目的查是否开奖 如果state 已经在抽奖中了 我们是不需要加人进来的

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector); //猜测下一个调用必会revert 因为已经正在开奖中了 这个奖池正常来说已经进不去了
        //检查一下到底开没开
        vm.prank(PLAYER); //对比一下是不是他开的
        raffle.enterRaffle{value: entranceFee}(); //二次验证后发现 确实被拒绝了e
    }
    //工作流程 Chainklink现在调用CHeckUPkeep(这个函数的存在形式为了定问合约现在可以开讲了么 是 Chainklink automaiton的接口函数系统)
    //chainlink节点定期调用CheckUpkeep  ---->返回true  节点自动调用 performUpkeep触发开奖  返回faalse 继续等待
    //这是测试思维核心，用AAA模式拆解checkup每个的条件  进行条件 的判断利用bool电路的特性来判断返回true 的时候需要满足几个条件 每个条件是否尅哟
    //例如：条件1 ：合约有ETH 余额
    // 条件2：有玩家参与 3 时间间隔已经过了 4 Raffle是open
    //审计视角：如果人为构造了某些条件触发了这个合约审计的判断，也就是这四个条件中的一个判断，则是否会引发该合约经济损失

    function testCheckUpkeepReturnsFalseEnoughTimeHasnt() public {
        vm.prank(PLAYER);

        raffle.enterRaffle{value: entranceFee}();

        (bool upkeepNeeded, ) = raffle.checkUpkeep(""); //忽略掉二哥返回值

        assert(!upkeepNeeded); // 断言upkeep不需要执行
    }

    function testCheckUpkeepReturnsTrueWhenParametersGood() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        //规则拆解：raffleEntranceFee= 在setU配置中获得了入场配置
        //{value：。。}这个是一美元。放在交易内发出去
        //enterRaffle() 合约内部检查msg.value》=entranceFee
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        //在第一轮开奖之后，验证如果没有余额了应该拒绝开奖的场景，制造一些条件 然后来看是否满足最终的抽奖条件的过程
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        //如何推动他们进行下一步开奖，就是要更改他们两个的时间，一个是完成时间在 结束后加以 一个是区块加以依此证明时间在开奖之后。
        (bool upkeepNeeded, ) = raffle.checkUpkeep(""); //调用合约的checkUpkeep函数，并且传入空字节 为啥传入空字节 因为 函数签名要求串bytes calldata 但是这里没
        //规定函数返回 这个 returns(bool upkeepNeeded,bytes memory performdata)
        //为啥只要第一个？ 因为 这个upkeepNeeded 是回答能不能得 而后面的是附加数据的

        assert(!upkeepNeeded); //判断是否开讲了 如果没开奖的话这里反倒是可以通过的状态 如果是true的话测试爆红
    } //这个测试的原因是没有余额，下全部不满足扔他条件
    //验证处于 Calculating状态的时候 checkupkeep拒绝开奖

    //新增测试：测试 testCheckUpKeep 如果时间为过则返回false 测试时间所以不写时间

    function testCheckUpkeepReturnsFalseRaffleIsntOpen() public {
        vm.prank(PLAYER); //切换下一个玩家为 player 模拟下
        raffle.enterRaffle{value: entranceFee}(); //带着player 进行抽检同时满足了 hashbalance跟 hasplayer俩条件 其中
        //想到 value 多了会咋办少了会咋办 审计点
        //raffle.enterRaffle 调用raffle合约实力的enterRaffle的函数
        //{value:raffleEntranceFee}这个调用附加的eth 这个还是 solidity 附加的 eth的语法 符合的入场费
        //为啥用value  因为enterRaffle payable 不带eht的话 会revert
        //为了满足时间的问题
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");

        //这个是 组边是声明一个变量接住返回的值，类型是Raffle.RaffleState  这个Raffle.raffleState raffleState 这个只能装rafll额state的值
        // raffle.getRaffleState 指的是 调用合约的getter的函数并且返回当前状态的值
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        //把之前给那OPEN 跟 Call那个状态集成到咱们这个合约中

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(raffleState == Raffle.RaffleState.CALCULATING); //看看这个状态是不是CALCUALATAING的状态 验证一下为啥是不是。

        assert(upkeepNeeded == false);
    }
    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        //
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act
        raffle.performUpkeep("");
    }
    //通过故意营造各种不满足的状态来检查确保，这个performUpkeep这个函数不会被触发
    function testPerformUpkeepRevertsIfCheckUpkeeplsFalse() public {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;

        Raffle.RaffleState rState = raffle.getRaffleState(); //将获取 状态值 STATE的函数值boole 一个open一个Call这个抓那题搬到这里阿里
        //电路来说全是false
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance, //0不满足条件
                numPlayers, //0
                rState //open、
            )
        );
        raffle.performUpkeep("");
    }
}
