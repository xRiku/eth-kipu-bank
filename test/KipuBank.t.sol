// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {KipuBank} from "../src/KipuBank.sol";

uint256 constant WITHDRAW_LIMIT_PER_TRANSACTION = 2 ether;
uint256 constant BANK_CAP = 100 ether;

contract KipuBankTest is Test {
    KipuBank public kipubank;

    function setUp() external {
        kipubank = new KipuBank(WITHDRAW_LIMIT_PER_TRANSACTION, BANK_CAP);
    }

    function testGetBalance() external view {
        assertEq(kipubank.getBankBalance(), 0);
    }

    function testGetBankCap() external view {
        assertEq(kipubank.getBankCap(), BANK_CAP);
    }

    function testVerifyOwnership() external {
        address addr = address(0x1);
        vm.deal(addr, 1 ether);
        vm.prank(addr);
        kipubank.deposit{value: 0.1 ether}();
        assertTrue(kipubank.verifyOwnership(addr));
    }

    function testOwnershipFails() external view {
        address addr = address(0x1);
        assertFalse(kipubank.verifyOwnership(addr));
    }

    function testGetWithdrawLimitPerTransaction() external view {
        assertEq(kipubank.getWithdrawLimitPerTransaction(), WITHDRAW_LIMIT_PER_TRANSACTION);
    }

    function testRevert_WhenDepositingZeroValue() external {
        vm.expectRevert();
        kipubank.deposit(); // 0 value
    }

    function testRevert_WhenDepositAmountIsNotEnough() external {
        vm.expectRevert();
        kipubank.deposit{value: 0.004 ether}();
    }

    function testDepositWithinConstraints() external {
        kipubank.deposit{value: 0.006 ether}();

        assertEq(address(kipubank).balance, 0.006 ether);
    }

    function testRevert_DepositExceedingBankCap() external {
        vm.expectRevert();
        kipubank.deposit{value: 100.001 ether}();
    }

    function testWithdraw() external {
        address addr = address(0x1);
        vm.deal(addr, 1 ether);

        vm.prank(addr);
        kipubank.deposit{value: 0.1 ether}();

        vm.prank(addr);
        kipubank.withdraw(0.05 ether);

        assertEq(address(kipubank).balance, 0.05 ether);
        assertEq(addr.balance, 0.95 ether);
    }

    function testRevert_WithdrawWhenAddressIsNotOwner() external {
        address addr = address(0x1);
        vm.deal(addr, 1 ether);

        vm.expectRevert(KipuBank.KipuBank__NotOwner.selector);
        vm.prank(addr);
        kipubank.withdraw(0.05 ether);
    }

    function testRevert_WithdrawExceedsLimit() external {
        address addr = address(0x1);
        vm.deal(addr, 10 ether);

        vm.prank(addr);
        kipubank.deposit{value: 10 ether}();

        vm.expectRevert();
        vm.prank(addr);
        kipubank.withdraw(2.05 ether);
    }
}
