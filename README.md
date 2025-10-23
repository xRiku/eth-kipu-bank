# KipuBank

Simple on-chain savings bank implemented in Solidity.

This repository contains `KipuBank.sol`, a minimal contract that lets any address deposit Ether, tracks per-address balances, enforces a per-transaction withdrawal limit and an overall bank cap (both set at deployment and immutable).

## Key ideas

- Per-address accounting: deposits are tracked in a `funds` mapping and each depositing address is recorded in `owners`.
- Immutable limits: `i_withdrawLimitPerTransaction` and `i_bankCap` are set in the constructor and cannot be changed.
- Safety checks: deposits and withdrawals validate amounts and will revert with custom error types on invalid conditions.
- Minimal feature set: there are no privileged (owner-only) functions — the contract is intended as a small example/bank.

## Contract summary

Filename: `src/KipuBank.sol`

Public immutable state:

- `i_withdrawLimitPerTransaction` (uint256) — maximum allowed withdrawal per transaction (in wei).
- `i_bankCap` (uint256) — maximum allowed total balance of the contract (in wei).

Storage & helpers:

- `owners` (address[]) — list of unique addresses that have deposited.
- `isOwner` (mapping(address => bool)) — helper to check if an address is already recorded.
- `funds` (mapping(address => uint256)) — per-address deposited balance.

Errors (custom):

- `InvalidDepositAmount()` — deposit value must be > 0.
- `ExceedsWithdrawLimit()` — attempted withdrawal > per-transaction limit.
- `InsufficientFunds()` — trying to withdraw more than an address balance.
- `BankCapExceeded()` — deposit would push contract balance above `i_bankCap`.
- `TransactionFailed()` — low-level call to transfer Ether failed.
- `InvalidWithdrawLimitPerTransactionValue()` / `InvalidBankCapAmount()` — invalid constructor args (non-zero required).

Public functions

- `deposit()` payable: deposit Ether. Registers the sender in `owners` (first deposit) and increases `funds[msg.sender]`. Reverts if deposit is 0 or deposit would exceed the bank cap.
- `withdraw(uint256 _amount)` payable: withdraw up to `i_withdrawLimitPerTransaction` and up to the caller's balance. Uses a low-level `call` to send Ether and reverts on failure.
- `getBalance()` view returns (uint256): the contract's Ether balance.
- `getBankCap()` view returns (uint256): returns `i_bankCap`.
- `getWithdrawLimitPerTransaction()` view returns (uint256): returns `i_withdrawLimitPerTransaction`.

## Constructor

constructor(uint256 \_withdrawalLimitPerTransaction, uint256 \_bankCap)

- `_withdrawalLimitPerTransaction`: per-transaction withdrawal limit in wei (must be > 0).
- `_bankCap`: maximum total contract balance in wei (must be > 0).

Example values (human readable):

- 1 ether withdrawal limit: `1000000000000000000` (wei)
- 100 ether bank cap: `100000000000000000000` (wei)

## Quick usage

Prerequisites: Foundry installed (forge, cast) or an ethers.js/Hardhat environment.

Run tests (Foundry):

```bash
forge test
```

Deploy with Foundry (example):

```bash
# replace <PRIVATE_KEY> and <RPC_URL>
forge create --private-key <PRIVATE_KEY> --rpc-url <RPC_URL> src/KipuBank.sol:KipuBank --constructor-args 1000000000000000000 100000000000000000000
```

Deploy with ethers.js (example):

```js
// simple deploy snippet (node)
const { ethers } = require("ethers");
const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_URL);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

const compiled = require("./out/KipuBank.json"); // adjust path to your build output
const factory = new ethers.ContractFactory(
  compiled.abi,
  compiled.bytecode,
  wallet
);

const withdrawLimit = ethers.utils.parseEther("1");
const bankCap = ethers.utils.parseEther("100");

async function deploy() {
  const contract = await factory.deploy(withdrawLimit, bankCap);
  await contract.deployed();
  console.log("KipuBank deployed at", contract.address);
}

deploy();
```

Interact (send deposit / withdraw) with ethers.js:

```js
// deposit 0.5 ETH
await wallet.sendTransaction({
  to: kipuAddress,
  value: ethers.utils.parseEther("0.5"),
});

// withdraw 0.5 ETH (call the contract withdraw method)
const kipu = new ethers.Contract(kipuAddress, compiled.abi, wallet);
await kipu.withdraw(ethers.utils.parseEther("0.5"));
```

Note: the example deposit via plain `sendTransaction` will not update the `owners`/`funds` mapping because `deposit()` is the payable function that records deposits; to call the contract's `deposit()` you must call the contract method explicitly:

```js
await kipu.deposit({ value: ethers.utils.parseEther("0.5") });
```

## Security notes & limitations

- No reentrancy guard: `withdraw` decreases the caller's `funds` before performing the external call, which is a safer order, but the contract still exposes an external call. Consider adding a reentrancy guard (`ReentrancyGuard`) if expanding functionality.
- `owners` array grows without a way to remove addresses — this may cause unbounded gas if used as an on-chain registry for large numbers of users.
- There are no admin/owner-only controls. Limits are immutable; if you need adjustable settings add carefully restricted management functions.
- The contract uses a low-level `call` for Ether transfers and correctly checks the return value.

## Improvements (suggested)

- Add events for Deposit and Withdraw to make monitoring easier.
- Add a `withdrawAll` with safety checks or a timelock for larger withdrawals.
- Add role-based access control or governance to update caps/limits if desired.

## License

MIT
