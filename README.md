# Credible Layer Example Project

This repository provides a minimal example of a Credible Layer assertion setup, designed to demonstrate the fundamental structure and implementation of assertions in a project.

## Overview

This project serves as a template for implementing Credible Layer assertions. You can use this structure as a foundation for your own projects. The content is based on the [Credible Layer Quickstart Guide](https://docs.phylax.systems/credible/pcl-quickstart).

For additional examples and detailed documentation, please refer to:

- [Assertion Examples Repository](https://github.com/phylaxsystems/assertion-examples)
- [Assertions Book](https://docs.phylax.systems/assertions-book/assertions-book-intro)

## Prerequisites

Before getting started, ensure you have:

- Phylax Credible CLI (`pcl`) installed
  - Follow the [Credible Layer Installation Guide](https://docs.phylax.systems/credible/credible-install)
  - Alternatively, install directly using:

    ```bash
    cargo +nightly install --git https://github.com/phylaxsystems/pcl --locked
    ```

- [Foundry](https://getfoundry.sh/) installed
- [Solidity](https://docs.soliditylang.org/en/latest/installing-solidity.html) installed

## Getting Started

### Clone the Repository

This repository uses Git submodules. Clone it using:

```bash
git clone --recurse-submodules https://github.com/phylaxsystems/credible-layer-starter.git
```

If you've already cloned without submodules, initialize them with:

```bash
git submodule update --init --recursive
```

### Project Setup

The project comes pre-configured with:

- `credible-std`: Core Credible Layer functionality
- `forge-std`: Forge standard library that we rely on for testing
- `openzeppelin-contracts`: OpenZeppelin contracts

Install any additional dependencies your project requires.

## Testing Assertions

Before deploying any contracts or assertions, you should test the assertions to ensure they are working.

Run the test suite using:

```bash
pcl test
```

This command executes tests located in the `assertions/test` directory.

## Deployment

Note: For convenience you can set the environment variables as defined below.

### Deploy PhyLock

```bash
# Set environment variables
export PRIVATE_KEY=0x...  # Your private key with 0x prefix
export RPC_URL=phylax_demo_rpc_url

# Deploy the contract
forge script script/DeployPhyLock.s.sol --rpc-url $RPC_URL --sender $DEPLOYER_ADDRESS --broadcast
```

### Deploy SimpleLending

```bash
# Set environment variables
export PRIVATE_KEY=0x...  # Your private key with 0x prefix
export DEPLOYER_ADDRESS=0x...  # Your deployer address
export RPC_URL=phylax_demo_rpc_url

# Deploy the contract
forge script script/DeploySimpleLending.s.sol --rpc-url $RPC_URL --sender $DEPLOYER_ADDRESS --broadcast
```

### Deploy Ownable

```bash
# Set environment variables
export PRIVATE_KEY=0x...  # Your private key with 0x prefix
export DEPLOYER_ADDRESS=0x...  # Your deployer address
export RPC_URL=phylax_demo_rpc_url

# Deploy the contract
forge script script/DeployOwnable.s.sol --rpc-url $RPC_URL --sender $DEPLOYER_ADDRESS --broadcast
```

## Authenticating and Creating Projects

To authenticate, run:

```bash
pcl auth login
```

Then follow the instructions to authenticate in your browser.

When authenticated in the browser you can create a project in the dapp.

When you create a project you specify which contract(s) the project is for.

## Storing Assertions

Once a project is created you can store assertions for it.
To store assertions, run:

```bash
pcl store <assertion-name> <constructor-args>
```

For example, to store the `OwnableAssertion` assertion with the constructor arguments `0x1234567890123456789012345678901234567890`:

```bash
pcl store OwnableAssertion 0x1234567890123456789012345678901234567890
```

This means that the assertion will be protecting the contract with address `0x1234567890123456789012345678901234567890`.

## Submitting Assertions

To submit assertions, run:

```bash
pcl submit
```

This gives you an interactive prompt to submit assertions.

To be more specific, you can submit a single assertion with:

```bash
pcl submit -a <assertion-name> -p <project-name>
```

For example, to submit the `OwnableAssertion` assertion to a project named `foobar`:

```bash
pcl submit -a 'OwnableAssertion(0x1234567890123456789012345678901234567890)' -p foobar
```

This is assuming the project you created is named `foobar`.

## Activating Assertions

Once the assertions are submitted, you can activate them by going back to the dapp, clicking your project and then reviwing the assertions
that are marked as "Ready for Review". Once this is done, you sign a transaction that activates the assertion(s).

Your contract is now protected and you can go ahead and run the transactions below for a given protocol.

## Transaction Execution

We've prepared a set of transactions to interact with each protocol. These are located in the `script` directory.

Before you run the transactions you should make sure to store, submit and activate the assertions as described above.

Note, for each of the protocols below, you can refer to the [Credible Layer Quickstart Guide](https://docs.phylax.systems/credible/pcl-quickstart) in order for more context and explanations on how to use the pcl and dapp to store, submit and activate assertions.

When an assertion is reverted, the transaction causing the revert will be ignored by the builder. This means that the `cast` or `forge` command will not show any output indicating that the transaction was reverted, it will just timeout after a while. You can use the `--timeout` flag to decrease the timeout.

```bash
Error: transaction was not confirmed within the timeout
```

If you try to do another transaction with the same private key, you will most likely get this a replacement transaction error:

```bash
- server returned an error response: error code -32603: replacement transaction underpriced
```

This is a known limitation of the system - when an assertion reverts a transaction, it gets dropped by the builder rather than being included in a block. This means that wallets and tools like `cast` will still increment their local nonce, potentially causing issues with subsequent transactions. While this creates some UX friction, it only occurs when someone attempts to violate an assertion (i.e., attempt to hack a protocol), so we consider this an acceptable tradeoff. In the future, we plan to work with wallet providers to better surface these dropped transactions.

We recommend doing a simple ether transfer with a higher gas price, to replace the dropped transaction:

```bash
cast nonce <your-address> --rpc-url <your-rpc>
```

and then use the nonce to send a new transaction:

```bash
cast send <your-address> --value 0 --gas-price <higher-gas-price> --nonce <nonce> --private-key <your-private-key> --rpc-url <your-rpc>
```

Alternatively, you can use the provided script to handle this automatically:

```bash
# Set environment variables
export PRIVATE_KEY=0x...  # Your private key with 0x prefix
export RPC_URL=your_rpc_url

# Run the script with a higher gas price
forge script script/ExecuteTransactionReset.s.sol --rpc-url $RPC_URL --broadcast --gas-price 100000000000  # 100 gwei
```

This script will send a 0 ETH transaction to your own address with the specified gas price, effectively replacing any stuck transactions. If it doesn't work try increasing the gas price further.

### PhyLock

A staking protocol that allows users to deposit ETH and earn Phylax tokens as rewards.
It seems the developers have spent more time defining their invariants than actually implementing the protocol.
Because of this there are critical bugs present in the protocol:

- Any address that hasn't deposited can call `withdraw` to receive an arbitrary amount of ETH deposited by other users.
- There is no check that `transferOwnership` can only be called by the owner.
- The owner can call `mint` to mint an arbitrary amount of Phylax tokens to any address.

Luckily, there are assertions in place that make sure the protocol maintains the invariant that user deposit balance must decrease according to the amount of eth withdrawn as well as not allowing the owner to transfer ownership to an arbitrary address.

```bash
# Set environment variables
export PRIVATE_KEY=0x...  # Your private key with 0x prefix
export PHYLOCK_ADDRESS=0x...  # Your deployed contract address
export RPC_URL=phylax_demo_rpc_url

# Run individual test functions
# Deposit 0.7 eth from the private key - should succeed as it's intented behavior
forge script script/ExecuteTransactionsPhyLock.s.sol --sig "deposit()" --rpc-url $RPC_URL --broadcast

# Withdraw 0.2 eth from the private key - should succeed as it's intented behavior (you received phylax tokens as a reward)
forge script script/ExecuteTransactionsPhyLock.s.sol --sig "withdraw()" --rpc-url $RPC_URL --broadcast

# Withdraw 0.5 eth without depositing - this should fail due to the assertion
# Before running this, you should change the private key to one that hasn't deposited
forge script script/ExecuteTransactionsPhyLock.s.sol --sig "withdrawWithoutDeposit()" --rpc-url $RPC_URL --broadcast

# Transfer ownership to an arbitrary address - this should fail due to the assertion
forge script script/ExecuteTransactionsPhyLock.s.sol --sig "transferOwnership()" --rpc-url $RPC_URL --broadcast
```

### SimpleLending

A lending protocol that allows users to deposit ETH as collateral and borrow tokens against it. The protocol uses a price feed to determine the value of collateral and calculate safe borrowing limits.

The protocol has several critical vulnerabilities:

- Users can withdraw more collateral than they should be allowed to, potentially draining the protocol
- The price feed can be manipulated to affect borrowing limits
- The price feed can be updated with unsafe price changes (more than 10% change)
- There's a buggy withdrawal function that doesn't check collateral ratios

Luckily, there are assertions in place that:

- Prevent unsafe withdrawals that would violate collateral requirements
- Ensure price feed updates are valid and not manipulated
- Prevent price changes that exceed 10% threshold
- Maintain the invariant that total protocol collateral must match the sum of user deposits

```bash
# Set environment variables
export PRIVATE_KEY=0x...  # Your private key with 0x prefix
export LENDING_PROTOCOL=0x...  # Your deployed contract address
export TOKEN_ADDRESS=0x...  # Your token contract address
export RPC_URL=phylax_demo_rpc_url
export PRICE_FEED=0x...  # Your price feed contract address

# Test withdrawal scenarios
# Attempt to withdraw more than allowed by collateral ratio - should fail due to assertion
forge script script/ExecuteTransactionsSimpleLending.s.sol --sig "testUnsafeWithdrawal()" --rpc-url $RPC_URL --broadcast

# Withdraw a safe amount - should succeed as it's intended behavior
forge script script/ExecuteTransactionsSimpleLending.s.sol --sig "testSafeWithdrawal()" --rpc-url $RPC_URL --broadcast

# Attempt to drain the protocol using the buggy withdrawal function - should fail due to assertion
forge script script/ExecuteTransactionsSimpleLending.s.sol --sig "testProtocolDrain()" --rpc-url $RPC_URL --broadcast

# Normal withdrawal within limits - should succeed as it's intended behavior
forge script script/ExecuteTransactionsSimpleLending.s.sol --sig "testNormalWithdrawal()" --rpc-url $RPC_URL --broadcast

# Test price feed scenarios
# Update price with a safe 5% increase - should succeed as it's intended behavior
forge script script/ExecuteTransactionsPriceFeed.s.sol --sig "testSafePriceUpdate()" --rpc-url $RPC_URL --broadcast

# Attempt to decrease price by 15% - should fail due to assertion
forge script script/ExecuteTransactionsPriceFeed.s.sol --sig "testUnsafePriceDecrease()" --rpc-url $RPC_URL --broadcast

# Attempt to increase price by 15% - should fail due to assertion
forge script script/ExecuteTransactionsPriceFeed.s.sol --sig "testUnsafePriceIncrease()" --rpc-url $RPC_URL --broadcast

# Test batch price updates with multiple changes - should fail when hitting 15% change
forge script script/ExecuteTransactionsPriceFeed.s.sol --sig "testBatchPriceUpdates()" --rpc-url $RPC_URL --broadcast
```

### Ownable

A basic implementation of the Ownable pattern that demonstrates ownership management in smart contracts. The contract allows the owner to transfer ownership to other addresses.

A lot of hacks lately are caused by compromised owner accounts, so we have added an assertion to make sure that the owner cannot be changed.

```bash
# Set environment variables
export PRIVATE_KEY=0x...  # Your private key with 0x prefix
export OWNABLE_ADDRESS=0x...  # Your deployed contract address
export RPC_URL=phylax_demo_rpc_url

# Attempt to transfer ownership from a non-owner address - should fail due to assertion
forge script script/ExecuteTransactionsOwnable.s.sol --sig "testTransferOwnership()" --rpc-url $RPC_URL --broadcast
```

## Additional Resources

Please refer to the [Credible Layer Quickstart Guide](https://docs.phylax.systems/credible/pcl-quickstart) for comprehensive documentation on the Credible Layer and guides for getting started.
