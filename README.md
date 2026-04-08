## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```


#可证明的随机数抽奖合约

# 关于

#这段代码用于创建一个随机可证明的代码的智能合约彩票

#我们希望他做啥？
1 .任何人都可以通过花钱锻造彩票 ，并且可以通过他们获取一定的报酬，彩票的费用作为中奖者的奖品
2 .彩票要在一定方式以程序化的方式自动抽取中奖者 
3.Chainklink VRF可生成一个随机数 并且这个随机数可以证明是随机的
4。Chianklink Automaticion 应该定期的触发抽奖系统体系。
