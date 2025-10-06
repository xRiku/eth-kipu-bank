// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {KipuBank} from "../src/KipuBank.sol";

uint256 constant WITHDRAW_LIMIT_PER_TRANSACTION = 2 * 1e18; // 2 ETH;
uint256 constant BANK_CAP = 100 * 1e18; // 100 ETH;

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

    function testDepositFailsWithZeroValue() external {
        vm.expectRevert();
        kipubank.deposit(); // 0 value
    }

    function testDepositFailsWithNotEnouthDepositAmount() external {
        vm.expectRevert();
        kipubank.deposit{value: 0.004 * 1e18}();
    }

    function testDepositWithinConstraints() external {
        kipubank.deposit{value: 0.006 * 1e18}();

        assertEq(address(kipubank).balance, 0.006 * 1e18);
    }
}
