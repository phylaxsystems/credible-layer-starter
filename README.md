# Credible Layer Starter

A minimal, working template for writing, testing, and deploying Credible Layer assertions.
This repo mirrors the public quickstart and keeps the steps as short as possible for first-time users.

## What's Inside

- `assertions/src`: Assertion contracts (Solidity)
- `assertions/test`: Assertion tests runnable with `pcl test`
- `assertions/credible-example.toml`: Example deployment configuration for `pcl apply`
- `src`: Example protocols with intentional vulnerabilities
- `script`: Deployment scripts for the example protocols
- `lib`: Submodules for `credible-std`, `forge-std`, and OpenZeppelin

## Prerequisites

- `pcl` installed (quick path): https://docs.phylax.systems/credible/credible-install
- Foundry (`forge`, `cast`): https://getfoundry.sh/
- Git
- An RPC endpoint and funded wallet for a Credible Layer-enabled network

Quick install (macOS):

```bash
brew tap phylaxsystems/pcl
brew install phylax
```

Foundry install:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

## Quickstart (Ownable, 10 minutes)

This flow is the shortest path to a deployed assertion.

### 1) Clone with submodules

```bash
git clone --recurse-submodules https://github.com/phylaxsystems/credible-layer-starter.git
cd credible-layer-starter
```

If you already cloned:

```bash
git submodule update --init --recursive
```

### 2) Run assertion tests

```bash
pcl test
```

### 3) Deploy the Ownable example

```bash
export RPC_URL=...  # chain RPC URL

forge script script/DeployOwnable.s.sol \
  --rpc-url "$RPC_URL" \
  --account <account_name> \
  --broadcast
```

### 4) Authenticate and create a project

```bash
pcl auth login
```

- Open the login link in your browser.
- Create a project in the [platform](https://app.phylax.systems) and link the Ownable contract address.
- Ownership is verified via the network's admin verifier (typically `owner()` or allowlist-based).

### 5) Configure `credible.toml`

Copy the example configuration and update it with your deployed contract address:

```bash
cp assertions/credible-example.toml assertions/credible.toml
```

Edit `assertions/credible.toml`:

```toml
environment = "production"

[contracts.ownable]
address = "<ADDRESS_OF_DEPLOYED_CONTRACT>"
name = "Ownable"

[[contracts.ownable.assertions]]
file = "assertions/src/OwnableAssertion.a.sol"
```

### 6) Create a release with `pcl apply`

```bash
pcl apply
```

By default, `pcl apply` looks for `assertions/credible.toml`. To use a different path:

```bash
pcl apply -c path/to/credible.toml
```

This reads `credible.toml`, builds the assertion, and creates a release on the platform.
You'll be prompted to select a project (if `project_id` is not set in `credible.toml`) and to confirm the release.

### 7) Deploy in the platform

- Open the release link returned by `pcl apply`, or navigate to your project in [app.phylax.systems](https://app.phylax.systems).
- Review and deploy the assertion to **Staging** or **Production**.
- After the timelock, it becomes staged/enforced and starts protecting transactions.

### 8) Verify it works

```bash
export OWNABLE_ADDRESS=0x...  # deployed Ownable address

# Check current owner
cast call "$OWNABLE_ADDRESS" "owner()" --rpc-url "$RPC_URL"

# Attempt to transfer ownership (should be dropped if assertion is enforced)
cast send "$OWNABLE_ADDRESS" \
  "transferOwnership(address)" 0x1234567890123456789012345678901234567890 \
  --account <account_name> \
  --rpc-url "$RPC_URL" \
  --timeout 20

# Owner should be unchanged
cast call "$OWNABLE_ADDRESS" "owner()" --rpc-url "$RPC_URL"
```

If the transaction times out, the assertion likely dropped it. Some clients require a higher gas price to replace dropped txs.

## Other Example Protocols

The repo includes two larger examples with dedicated assertions:

### PhyLock

- Contract: `src/PhyLock.sol`
- Assertions: `PhyLockAssertion`, `OwnershipAssertion`
- Deploy: `script/DeployPhyLock.s.sol`

### SimpleLending

- Contract: `src/SimpleLending.sol`
- Assertions: `SimpleLendingAssertion`, `PriceFeedAssertion`
- Deploy: `script/DeploySimpleLending.s.sol`

The end-to-end flow is the same as the Ownable example:
1) Deploy the contract(s)
2) Create a project and link contract addresses
3) Add the contracts and assertions to `credible.toml` (see `assertions/credible-example.toml`)
4) `pcl apply`
5) Deploy in the platform (staging/production)
6) Run the provided `cast` transactions below

## Transaction Exercises

Use the commands below after you have deployed the contracts and deployed assertions in the platform.

### PhyLock

Deploy these assertions in the platform before running the transactions:
- `PhyLockAssertion` for the PhyLock contract
- `OwnershipAssertion` for the same contract

```bash
export PHYLOCK_ADDRESS=0x...
export RPC_URL=...

# Deposit 0.7 ETH
cast send "$PHYLOCK_ADDRESS" "deposit()" --value 0.7ether --account <account_name> --rpc-url "$RPC_URL"

# Withdraw 0.2 ETH
cast send "$PHYLOCK_ADDRESS" "withdraw(uint256)" 0.2ether --account <account_name> --rpc-url "$RPC_URL"

# Withdraw 69 ETH (should be dropped)
cast send "$PHYLOCK_ADDRESS" "withdraw(uint256)" 69ether --account <account_name> --rpc-url "$RPC_URL" --timeout 20

# Transfer ownership (should be dropped)
cast send "$PHYLOCK_ADDRESS" \
  "transferOwnership(address)" 0x1234567890123456789012345678901234567890 \
  --account <account_name> \
  --rpc-url "$RPC_URL" \
  --timeout 20 \
  --gas-price 100000000000
```

### SimpleLending

Make sure your `credible.toml` includes both the lending contract and the price feed contract, then deploy:
- `SimpleLendingAssertion` for `SimpleLending`
- `PriceFeedAssertion` for the price feed

```bash
export LENDING_PROTOCOL=0x...
export TOKEN_ADDRESS=0x...
export PRICE_FEED=0x...
export RPC_URL=...

# Mint tokens to the lending protocol
cast send "$TOKEN_ADDRESS" "mint(address,uint256)" "$LENDING_PROTOCOL" 100000ether --account <account_name> --rpc-url "$RPC_URL"

# Deposit 0.5 ETH
cast send "$LENDING_PROTOCOL" "deposit()" --value 0.5ether --account <account_name> --rpc-url "$RPC_URL"

# Borrow 750 tokens
cast send "$LENDING_PROTOCOL" "borrow(uint256)" 750ether --account <account_name> --rpc-url "$RPC_URL"

# Withdraw collateral (should be dropped)
cast send "$LENDING_PROTOCOL" "withdraw(uint256)" 0.25ether --account <account_name> --rpc-url "$RPC_URL" --timeout 20

# Decrease price by 15% (should be dropped)
cast send "$PRICE_FEED" "setPrice(uint256)" 0.75ether --account <account_name> --rpc-url "$RPC_URL" --timeout 20 --gas-price 100000000000
```

## Additional Resources

- Quickstart: https://docs.phylax.systems/credible/pcl-quickstart
- Apply assertions: https://docs.phylax.systems/credible/apply-assertions
- Deploy with the platform: https://docs.phylax.systems/credible/deploy-assertions-dapp
- Assertions Book: https://docs.phylax.systems/assertions-book/assertions-book-intro
- Examples: https://github.com/phylaxsystems/assertions-examples
