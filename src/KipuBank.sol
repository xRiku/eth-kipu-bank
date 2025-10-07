// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract KipuBank {
    uint256 private immutable i_withdrawLimitPerTransaction;
    uint256 private immutable i_bankCap;

    address[] private owners;
    mapping(address => bool) isOwner;
    mapping(address => uint256) funds;

    error InvalidDepositAmount();
    error ExceedsWithdrawLimit();
    error InsufficientFunds();
    error BankCapExceeded();
    error TransactionFailed();

    error InvalidWithdrawLimitPerTransactionValue();
    error InvalidBankCapAmount();

    modifier onlyOwner() {
        if (!isOwner[msg.sender]) {
            revert("Not an owner");
        }
        _;
    }

    constructor(uint256 _withdrawalLimitPerTransaction, uint256 _bankCap) {
        if (_withdrawalLimitPerTransaction == 0) {
            revert InvalidWithdrawLimitPerTransactionValue();
        }

        if (_bankCap == 0) {
            revert InvalidBankCapAmount();
        }

        i_withdrawLimitPerTransaction = _withdrawalLimitPerTransaction;
        i_bankCap = _bankCap;
    }

    function withdraw(uint256 _amount) external payable onlyOwner {
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
        if (msg.value < 0.005 * 1e18) {
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

    /**
     * View / Pure functions (Getters)
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getBankCap() external view returns (uint256) {
        return i_bankCap;
    }

    function getWithdrawLimitPerTransaction() external view returns (uint256) {
        return i_withdrawLimitPerTransaction;
    }

    function verifyOwnership(address addr) external view returns (bool) {
        return isOwner[addr];
    }
}
