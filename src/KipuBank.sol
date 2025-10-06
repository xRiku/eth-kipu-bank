// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract KipuBank {
    uint256 public immutable i_withdrawLimitPerTransaction;
    uint256 public immutable i_bankCap;

    address[] public owners;
    mapping(address => bool) isOwner;
    mapping(address => uint256) funds;

    error InvalidDepositAmount();
    error ExceedsWithdrawLimit();
    error InsufficientFunds();
    error BankCapExceeded();
    error TransactionFailed();

    error InvalidWithdrawLimitPerTransactionValue();
    error InvalidBankCapAmount();

    constructor(uint256 _withdrawalLimitPerTransaction, uint256 _cap) {
        if (_withdrawalLimitPerTransaction == 0) {
            revert InvalidWithdrawLimitPerTransactionValue();
        }

        if (_cap == 0) {
            revert InvalidBankCapAmount();
        }

        i_withdrawLimitPerTransaction = _withdrawalLimitPerTransaction;
        i_bankCap = _cap;
    }

    function withdraw(uint256 _amount) external payable {
        address owner = msg.sender;

        if (funds[owner] <= 0) {
            revert InsufficientFunds();
        }

        if (_amount > i_withdrawLimitPerTransaction) {
            revert ExceedsWithdrawLimit();
        }

        if (funds[owner] < _amount) {
            revert InsufficientFunds();
        }

        funds[owner] -= _amount;

        (bool success,) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert TransactionFailed();
        }
    }

    function deposit() external payable {
        if (msg.value <= 0) {
            revert InvalidDepositAmount();
        }
        address owner = msg.sender;

        if (!isOwner[owner]) {
            isOwner[owner] = true;
            owners.push(owner);
        }

        funds[owner] += msg.value;

        if (address(this).balance > i_bankCap) {
            revert BankCapExceeded();
        }
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
