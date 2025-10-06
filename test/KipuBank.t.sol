// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {KipuBank} from "../src/KipuBank.sol";

uint256 constant WITHDRAW_LIMIT_PER_TRANSACTION = 2;
uint256 constant BANK_CAP = 100;

contract KipuBankTest is Test {
    KipuBank public kipubank;

    function setUp() external {
        kipubank = new KipuBank(WITHDRAW_LIMIT_PER_TRANSACTION, BANK_CAP);
    }

    function testGetBalance() external view {
        assertEq(kipubank.getBalance(), 0);
    }

    function testGetBankCap() external view {
        assertEq(kipubank.getBankCap(), BANK_CAP);
    }

    function testGetWithdrawLimitPerTransaction() external view {
        assertEq(kipubank.getWithdrawLimitPerTransaction(), WITHDRAW_LIMIT_PER_TRANSACTION);
    }
}
