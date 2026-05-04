//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import {DeployRaffle} from "../script/DeployRaffle.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {Test, console2} from "forge-std/Test.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

contract AttackRaffle {
    Raffle private raffle;
    uint256 private entranceFee;

    constructor(address _raffle, uint256 _entranceFee) {
        raffle = Raffle(_raffle);
        entranceFee = _entranceFee;
    }
    function attack() external payable {
        raffle.enterRaffle{value: entranceFee}();
    }

    receive() external payable {
        if (address(raffle).balance > 0) {
            raffle.enterRaffle{value: entranceFee}();
        }
    }
}
