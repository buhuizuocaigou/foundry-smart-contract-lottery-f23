//SPDEX:License-Identifier: MIT

// Layout of the contract file:
// version
// imports
// errors
// interfaces, libraries, contract​
//libraries:是一种可服用的函数集合 自己不存状态 不持有ETH 纯工具人

// Inside Contract:
// Type declarations
// State variables：链上存放的变量的值
// Events  ：不存到storage 中供前端的监听的东西
// Modifiers ：函数的前置检查并且检查一些啥东西部彻底上函数
// Functions​

// Layout of Functions:
// constructor初始化合约状态
// receive function (if exists) :让合约鞥收到EHT 能接受到的地方 得开一个地方撞他
// fallback function (if exists) :是否调用了工鞥函数吗 是否发生了溯回
// external ：只能从外部调用不能从内部济宁调用的方式 gas 币public省
// public：内外均可以调用的东西 编译器自动生成的外部接口系统
// internal
// private
// view & pure functions ：纯计算

pragma solidity ^0.8.19;

/**
 * @title 抽奖合同的范本
 * @author Nirenix
 * @notice 此合约用于创建实例的抽奖活动以及内容。
 * @dev 他实现了ChainkLINK VRF功能来实现随机数以及 Chainklink Automations 来实现抽奖功能
 */
error Raffle__NotEnoughETHEntered(); //使用自定义错误来干嘛排除当用户输入的ETH的金额过少的饿时候 提示错误目的是告知用户需要交更多的ETH

//声明动态数组用来存放东西的一个容器：

contract Raffle {
    uint256 private immutable i_entranceFee; //定义不可变的票价的价格并且是私有的 ,一旦可更改就不公平,immutable 是不可更改直接嵌入字节码中并且不耗费gas的变量
    //后面这个变量解决了抽奖时间的问题即为我们不希望只有两个忍就可以发起好凑将所以我们需要添加一些东西给他限制一下
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp; //上一次抽奖的最终值 这次得及时更改 不能像之前写死 他是动态可调整的所以不用immutable

    address payable[] private s_players; //定义一个动态数组来存放玩家的地址以及这个内容。
    //涉及到钱了 这里面存放了这么多 选取一个获取金钱
    event EnteredRaffle(address indexed player);

    //设置事件 进行事件设定 其中address是参数类型 player 是参数名字
    //这个indexed特有意思 让这个参数可以被链下的过滤器搜索 比如前端可以只监听某个特定地址的事件，比如EnteredRaffle事件 而不是遍历所有的事件内容想当于是多了一个地址索引
    //配合监听的是：emit 的内容 emit后的俱进路被写进交易日志 恋用你聚宝村  且只有前端能读 但是合约自己读不到告知这个部分是传递给前端的特定接口，
    //这个player 是自己起的名字

    //写死这个价格 放到字节码当中 不管是谁都无法改变这个价格
    constructor(uint256 entranceFee, uint256 interval) {
        //相当于是entranceFee是这个参数 部署完毕就消失了
        //这个书通过参数的entranceFee传进来赋值给i_entranceFee的值对吗
        i_entranceFee = entranceFee;
        i_interval = interval; //我自己设置的抽奖时间间隔写死的
        s_lastTimeStamp = block.timestamp; //这是一个新函数 这个block.timestamp的用途是当前这个区块的时间戳，指的是当下这个时间戳本身的内容
    }

    //部署着通过 constructor传入一个数字 这珠子赋值给了entranceFee 将其传入给了i_entranceFee 之后这个i_entranceFee就被写死在了字节码当中 任何人都无法改变这个价格 这就是immutable的作用并且借助immutable 这个写死目的让任何人不可以更改他们
    //设立上述vonsstructor的目的是为了当这算是初始化的过程 将 immutable 初始后的价格
    //需要俩个需求：1 用户通过支付票价参与抽奖

    //2 .某个时刻能选出来一名获胜的人不管是谁
    //抽奖的时间到底哪一个时刻中了？所以我们需要设置一个足厚的值
    //跟抽奖持续时间最相关的函数就是他 到底是哪一个时刻选择的呢 有待考虑ing
    function pickWinner() external {
        //确认开奖是否真的满足间隔时间
        //比如我设置600ms开 结果比他小 500ms开了
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert("weimanzu!");
        }
    }

    //目的是让人能看到这个抽奖价格是多少设立一个get函数
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee; //返回的是这个写死的价格
    }

    //如何检查这个i——entranceFee金额呢？
    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHEntered(); //如果用户输入的金额小于这个写死的价格 就抛出这个错误
        } //如果msg.value 即用户输入的比这个 原来规定的抽一次奖的单价逗笑的haul 返回单价错误告诉他ETH目前不够需要再次支付才可
        //.push的目的是为了向数组内推一个值让其加一
        s_players.push(payable(msg.sender));

        emit EnteredRaffle(msg.sender); //当用户成功进入抽奖后的话 就触发这个东西 同时把这个的值也可以传递给前端的人员
    } //if 跟 这个msg判断 搭配revert 一起 告诉他们如果不符合标准的haul只额吉revert回退 这个仅仅在solidity 高于0.8.4 才有

    //用户花钱了支付了门票后我们得有一个存放的地方 来存放谁花了钱购买了啥东西买了紧张 这时候我们需要用到 Arrray 且是可伸缩的动态数组来解决这个问题
}
