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

Note: For convenience you can set the environment variables as defined below, but you can also paste the values directly into the commands in place of the environment variables.

### Deploy PhyLock

```bash
# Set environment variables
export PRIVATE_KEY=0x...  # Your private key with 0x prefix
export DEPLOYER_ADDRESS=0x...  # Your deployer address
export RPC_URL=phylax_demo_rpc_url # phylax demo rpc url

# Deploy the contract
forge script script/DeployPhyLock.s.sol --rpc-url $RPC_URL --sender $DEPLOYER_ADDRESS --private-key $PRIVATE_KEY --broadcast
```

### Deploy SimpleLending

```bash
# Set environment variables
export PRIVATE_KEY=0x...  # Your private key with 0x prefix
export DEPLOYER_ADDRESS=0x...  # Your deployer address
export RPC_URL=phylax_demo_rpc_url # phylax demo rpc url

# Deploy the contract
forge script script/DeploySimpleLending.s.sol --rpc-url $RPC_URL --sender $DEPLOYER_ADDRESS --private-key $PRIVATE_KEY --tc DeployScript --broadcast
```

### Deploy Ownable

```bash
# Set environment variables
export PRIVATE_KEY=0x...  # Your private key with 0x prefix
export DEPLOYER_ADDRESS=0x...  # Your deployer address
export RPC_URL=phylax_demo_rpc_url # phylax demo rpc url

# Deploy the contract
forge script script/DeployOwnable.s.sol --rpc-url $RPC_URL --sender $DEPLOYER_ADDRESS --private-key $PRIVATE_KEY --broadcast
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
pcl store <assertion-name>
```

For example, to store the `OwnableAssertion` assertion:

```bash
pcl store OwnableAssertion
```

All assertions contracts in this repository use the `ph.getAssertionAdopter` cheatcode, which can be used instead of defining the contract to protect in the constructor.

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
pcl submit -a 'OwnableAssertion' -p foobar
```

This is assuming the project you created is named `foobar`.

## Activating Assertions

Once the assertions are submitted, you can activate them by going back to the dapp, clicking your project and then reviwing the assertions
that are marked as "Ready for Review". Once this is done, you sign a transaction that activates the assertion(s).

Your contract is now protected and you can go ahead and run the transactions below for a given protocol.

## Transaction Execution

We've prepared a set of transactions to interact with each protocol.

Before you run the transactions you should make sure to store, submit and activate the assertions as described above.

Note, for each of the protocols below, you can refer to the [Credible Layer Quickstart Guide](https://docs.phylax.systems/credible/pcl-quickstart) for more context and explanations on how to use the pcl and dapp to store, submit and activate assertions.

If you run into a `replacement transaction underpriced` error, you can follow the steps in the [Stuck Transactions](#stuck-transactions) section to replace the dropped transaction.

### PhyLock

A staking protocol that allows users to deposit ETH and earn Phylax tokens as rewards. (You can add the token to your browser wallet by pasting the PhyLock Token address that was returned by the deploy script.)
It seems the developers have spent more time defining their invariants than actually implementing the protocol.
Because of this there are critical bugs present in the protocol:

- Any address can call `withdraw` with the magic number `69 ether` to drain all the ETH in the protocol.
- There is no check that `transferOwnership` can only be called by the owner.
- The owner can call `mint` to mint an arbitrary amount of Phylax tokens to any address.

Luckily, there are assertions in place that make sure the protocol maintains the invariant that user deposit balance must decrease according to the amount of eth withdrawn as well as not allowing the owner to transfer ownership to an arbitrary address.

Go ahead and try to break the deployed protocol on `0xd296d45c0a56f3e3ea162796f29e525a668e3863` on the Phylax Sandbox.
There's at least 50 (test)ETH and unlimited Phylax (test)tokens in the protocol, so do your best.

Before running the transactions below, you should store, submit and activate the assertions as described above in the sections above.
Make sure to add both the `PhyLockAssertion` and `OwnershipAssertion` assertions to the project and activate them, to protect against all the critical bugs in the protocol.

```bash
# Set environment variables
export PRIVATE_KEY=0x...  # Your private key with 0x prefix
export PHYLOCK_ADDRESS=0x...  # Your deployed contract address
export RPC_URL=phylax_demo_rpc_url # phylax demo rpc url

# Run individual test functions
# Deposit 0.7 eth from the address of the private key - should succeed as it's intented behavior
cast send $PHYLOCK_ADDRESS "deposit()" --value 0.7ether --private-key $PRIVATE_KEY --rpc-url $RPC_URL

# Withdraw 0.2 eth from the address of the private key - should succeed as it's intented behavior (you received phylax tokens as a reward for staking)
cast send $PHYLOCK_ADDRESS "withdraw(uint256)" 0.2ether --private-key $PRIVATE_KEY --rpc-url $RPC_URL

# Call withdraw with the magic number 69 ether - this should fail due to the assertion
cast send $PHYLOCK_ADDRESS "withdraw(uint256)" 69ether --private-key $PRIVATE_KEY --rpc-url $RPC_URL --timeout 20

# Transfer ownership to an arbitrary address so that the new owner can mint phylax tokens to themselves
# This should fail due to the ownership assertion
# Note: you need to use a higher gas price here to replace the dropped transaction
cast send $PHYLOCK_ADDRESS "transferOwnership(address)" 0x1234567890123456789012345678901234567890 --private-key $PRIVATE_KEY --rpc-url $RPC_URL --timeout 20 --gas-price 100000000000
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

Before running the transactions below, you should store, submit and activate the assertions as described above in the sections above.
Make sure to add both the `SimpleLending deployed at:` and the `Token Price Feed deployed at:` addresses reported by the deploy script to the project.
Then activate the `SimpleLendingAssertion` for the SimpleLending contract and `PriceFeedAssertion` for the price feed contract, to protect against all the critical bugs in the protocol.

```bash
# Set environment variables
export PRIVATE_KEY=0x...  # Your private key with 0x prefix
export LENDING_PROTOCOL=0x...  # Your deployed SimpleLending contract address
export TOKEN_ADDRESS=0x...  # Your deployed token contract address
export RPC_URL=phylax_demo_rpc_url # phylax demo rpc url
export PRICE_FEED=0x...  # Your deployed price feed contract address

# Mint tokens to the lending protocol
cast send $TOKEN_ADDRESS "mint(address,uint256)" $LENDING_PROTOCOL 100000ether --private-key $PRIVATE_KEY --rpc-url $RPC_URL

# Deposit 0.5 ether
cast send $LENDING_PROTOCOL "deposit()" --value 0.5ether --private-key $PRIVATE_KEY --rpc-url $RPC_URL

# Borrow 750 tokens (75% of collateral value at $2000/ETH)
cast send $LENDING_PROTOCOL "borrow(uint256)" 750ether --private-key $PRIVATE_KEY --rpc-url $RPC_URL

# Withdraw 0.25 ether which makes the position unhealthy - this should fail due to the assertion making sure all positions are healthy
cast send $LENDING_PROTOCOL "withdraw(uint256)" 0.25ether --private-key $PRIVATE_KEY --rpc-url $RPC_URL --timeout 20

# Attempt to decrease price by 15% of the pricefeed simulating an oracle deviating too much
# Note: you need to use a higher gas price here to replace the dropped transaction
cast send $PRICE_FEED "setPrice(uint256)" 0.75ether --private-key $PRIVATE_KEY --rpc-url $RPC_URL --timeout 20 --gas-price 100000000000
```

### Ownable

A basic implementation of the Ownable pattern that demonstrates ownership management in smart contracts. The contract allows the owner to transfer ownership to other addresses.

A lot of hacks lately are caused by compromised owner accounts, so we have added an assertion to make sure that the owner cannot be changed.

```bash
# Set environment variables
export PRIVATE_KEY=0x...  # Your private key with 0x prefix
export OWNABLE_ADDRESS=0x...  # Your deployed contract address
export RPC_URL=phylax_demo_rpc_url # phylax demo rpc url

# Before running the transactions below, you should store, submit and activate the assertions as described above in the sections above.

# Check the initial owner
cast call $OWNABLE_ADDRESS "owner()" --rpc-url $RPC_URL

# Attempt to transfer ownership from a non-owner address - should fail due to assertion
cast send $OWNABLE_ADDRESS "transferOwnership(address)" 0x1234567890123456789012345678901234567890 --private-key $PRIVATE_KEY --rpc-url $RPC_URL --timeout 20

# Check that the owner did not change, since the assertion prevented the transaction from being executed
cast call $OWNABLE_ADDRESS "owner()" --rpc-url $RPC_URL
```

## Additional Resources

Please refer to the [Credible Layer Quickstart Guide](https://docs.phylax.systems/credible/pcl-quickstart) for comprehensive documentation on the Credible Layer and guides for getting started.

## Troubleshooting

### Stuck Transactions

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
cast send <your-address> --value 0 --gas-price <higher-gas-price> --private-key <your-private-key> --rpc-url <your-rpc>
```

This command will send a 0 ETH transaction to your own address with the specified gas price, effectively replacing any stuck transactions. If it doesn't work try increasing the gas price further.
