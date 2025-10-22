// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {KipuBank} from "src/KipuBank.sol";

contract KipuBankScript is Script {
    uint256 constant WITHDRAW_LIMIT = 0.1 ether;
    uint256 constant BANK_CAP = 20 ether;

    function setUp() public {}

    function run() external returns (KipuBank) {
        vm.startBroadcast();
        KipuBank kipuBank = new KipuBank(WITHDRAW_LIMIT, BANK_CAP);
        vm.stopBroadcast();
        return kipuBank;
    }
}
