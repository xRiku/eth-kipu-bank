// Layout of Contract:
// license
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title KipuBank
 * @author xRiku
 * @notice A minimal bank contract that allows owners to deposit and withdraw ETH
 *         subject to per-transaction withdrawal limits and a global bank cap.
 * @dev Stores per-owner balances and tracks ownership when an address first deposits.
 */
contract KipuBank {
    /* Errors */
    error KipuBank__InvalidDepositAmount();
    error KipuBank__WithdrawLimitExceeded();
    error KipuBank__InsufficientFunds();
    error KipuBank__BankCapExceeded();
    error KipuBank__TransactionFailed();
    error KipuBank__InvalidWithdrawLimitPerTransactionValue();
    error KipuBank__InvalidBankCapAmount();
    error KipuBank__NotOwner();
    error KipuBank__DirectDepositNotAllowed();
    error KipuBank__UnsupportedCall();

    struct TxCount {
        uint128 deposits;
        uint128 withdrawals;
    }

    /* State variables */
    uint256 private immutable i_withdrawLimitPerTransaction;
    uint256 private immutable i_bankCap;

    mapping(address => bool) private isOwner;
    mapping(address => uint256) private funds;
    TxCount private bankTxCount;
    mapping(address => TxCount) private ownerTxCount;

    /* Events */
    event OwnerRegistered(address indexed newOwner);
    event Deposit(address indexed from, uint256 amount, uint256 newBalance);
    event Withdraw(address indexed from, uint256 amount, uint256 remainingBalance);

    /**
     * @dev Restricts calls to registered owners. Reverts with a custom error when
     *      the caller is not an owner to keep revert reason compact.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        if (!isOwner[msg.sender]) {
            revert KipuBank__NotOwner();
        }
    }

    /**
     * @notice Deploys the KipuBank contract.
     * @dev Reverts when either constructor parameter is zero.
     * @param _withdrawalLimitPerTransaction Maximum amount an owner may withdraw per transaction (in wei).
     * @param _bankCap The maximum total ETH balance the bank may hold (in wei).
     */
    constructor(uint256 _withdrawalLimitPerTransaction, uint256 _bankCap) {
        if (_withdrawalLimitPerTransaction == 0) {
            revert KipuBank__InvalidWithdrawLimitPerTransactionValue();
        }

        if (_bankCap == 0) {
            revert KipuBank__InvalidBankCapAmount();
        }

        i_withdrawLimitPerTransaction = _withdrawalLimitPerTransaction;
        i_bankCap = _bankCap;
    }

    receive() external payable {
        revert KipuBank__DirectDepositNotAllowed();
    }

    fallback() external payable {
        revert KipuBank__UnsupportedCall();
    }

    /**
     * @notice Withdraw an amount of ETH from the caller's owned balance.
     * @dev Requires the caller to be an owner. Will revert if the owner's
     *      stored balance is insufficient, the requested amount exceeds the
     *      per-transaction withdrawal limit, or the external transfer fails.
     *      The function decreases the internal owner balance before performing
     *      the external call to prevent double-spend through reentrancy.
     * @param _amount The amount to withdraw (in wei).
     * @custom:reverts ExceedsWithdrawLimit when _amount > i_withdrawLimitPerTransaction.
     * @custom:reverts InsufficientFunds when the caller's stored balance is zero or less than _amount.
     * @custom:reverts TransactionFailed when the external transfer to the caller fails.
     */
    function withdraw(uint256 _amount) external onlyOwner {
        address owner = payable(msg.sender);
        uint256 balance = funds[owner];

        if (balance == 0) revert KipuBank__InsufficientFunds();
        if (_amount > i_withdrawLimitPerTransaction) revert KipuBank__WithdrawLimitExceeded();
        if (balance < _amount) revert KipuBank__InsufficientFunds();

        funds[owner] -= _amount;
        bankTxCount.withdrawals += 1;
        ownerTxCount[owner].withdrawals += 1;

        emit Withdraw(owner, _amount, funds[owner]);
        (bool success,) = owner.call{value: _amount}("");
        if (!success) {
            revert KipuBank__TransactionFailed();
        }
    }

    /**
     * @notice Deposit ETH into the bank and register the sender as an owner if new.
     * @dev Deposits smaller than 0.005 ETH (5 finney) are rejected. If the sender
     *      is not yet a registered owner, they become an owner upon deposit. The
     *      function updates the per-owner internal balance and ensures the bank
     *      does not exceed the configured cap.
     * @custom:reverts InvalidDepositAmount when msg.value is less than 0.005 ETH.
     * @custom:reverts BankCapExceeded when the resulting contract balance would exceed i_bankCap.
     */
    function deposit() external payable {
        if (msg.value < 0.005 * 1e18) {
            revert KipuBank__InvalidDepositAmount();
        }
        address owner = msg.sender;

        if (!isOwner[owner]) {
            isOwner[owner] = true;
            emit OwnerRegistered(owner);
        }

        funds[owner] += msg.value;
        bankTxCount.deposits += 1;
        ownerTxCount[owner].deposits += 1;

        if (address(this).balance > i_bankCap) {
            revert KipuBank__BankCapExceeded();
        }

        emit Deposit(owner, msg.value, funds[owner]);
    }

    /**
     * View / Pure functions (Getters)
     */
    function getBankBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getUserBalance(address user) external view returns (uint256) {
        return funds[user];
    }

    function getBankCap() external view returns (uint256) {
        return i_bankCap;
    }

    function getWithdrawLimitPerTransaction() external view returns (uint256) {
        return i_withdrawLimitPerTransaction;
    }

    function getOwnerTxCount(address owner) external view returns (uint128 deposits, uint128 withdrawals) {
        TxCount memory txc = ownerTxCount[owner];
        return (txc.deposits, txc.withdrawals);
    }

    function getBankTxCount() external view returns (uint128 deposits, uint128 withdrawals) {
        return (bankTxCount.deposits, bankTxCount.withdrawals);
    }

    /**
     * @notice Check whether an address is a registered owner.
     * @param addr The address to check.
     * @return True if the address is an owner, false otherwise.
     */
    function verifyOwnership(address addr) external view returns (bool) {
        return isOwner[addr];
    }
}
