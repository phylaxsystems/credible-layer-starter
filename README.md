# Credible Layer Starter

A minimal, working template for writing, testing, and deploying Credible Layer assertions.
This repo mirrors the public quickstart and keeps the steps as short as possible for first-time users.

## What's Inside

- `assertions/src`: Assertion contracts (Solidity)
- `assertions/test`: Assertion tests runnable with `pcl test`
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
export PRIVATE_KEY=0x...       # private key with 0x prefix
export DEPLOYER_ADDRESS=0x...  # address for the private key
export RPC_URL=...             # chain RPC URL

forge script script/DeployOwnable.s.sol \
  --rpc-url "$RPC_URL" \
  --sender "$DEPLOYER_ADDRESS" \
  --private-key "$PRIVATE_KEY" \
  --broadcast
```

### 4) Authenticate and create a project

```bash
pcl auth login
```

- Open the login link in your browser.
- Create a project in the dApp and link the Ownable contract address.
- Ownership is verified via the network's admin verifier (typically `owner()` or allowlist-based).

### 5) Store and submit the assertion

```bash
pcl store OwnableAssertion
pcl submit -a 'OwnableAssertion' -p <project_name>
```

This stores the assertion in Assertion DA and submits it to the dApp for deployment.
Project names are case-sensitive and must match the dApp exactly.
Note: the assertions in this repo use `ph.getAssertionAdopter()` so you link the contract in the dApp instead of passing it in a constructor.

### 6) Deploy in the dApp

- In the project view, deploy the assertion to **Staging** or **Production**.
- After the timelock, it becomes staged/enforced and starts protecting transactions.

### 7) Verify it works

```bash
export OWNABLE_ADDRESS=0x...  # deployed Ownable address

# Check current owner
cast call "$OWNABLE_ADDRESS" "owner()" --rpc-url "$RPC_URL"

# Attempt to transfer ownership (should be dropped if assertion is enforced)
cast send "$OWNABLE_ADDRESS" \
  "transferOwnership(address)" 0x1234567890123456789012345678901234567890 \
  --private-key "$PRIVATE_KEY" \
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
3) `pcl store` -> `pcl submit`
4) Deploy in the dApp (staging/production)
5) Run the provided `cast` transactions in the README below

## Transaction Exercises

Use the commands below after you have deployed the contracts and deployed assertions in the dApp.

### PhyLock

Deploy these assertions in the dApp before running the transactions:
- `PhyLockAssertion` for the PhyLock contract
- `OwnershipAssertion` for the same contract

```bash
export PRIVATE_KEY=0x...
export PHYLOCK_ADDRESS=0x...
export RPC_URL=...

# Deposit 0.7 ETH
cast send "$PHYLOCK_ADDRESS" "deposit()" --value 0.7ether --private-key "$PRIVATE_KEY" --rpc-url "$RPC_URL"

# Withdraw 0.2 ETH
cast send "$PHYLOCK_ADDRESS" "withdraw(uint256)" 0.2ether --private-key "$PRIVATE_KEY" --rpc-url "$RPC_URL"

# Withdraw 69 ETH (should be dropped)
cast send "$PHYLOCK_ADDRESS" "withdraw(uint256)" 69ether --private-key "$PRIVATE_KEY" --rpc-url "$RPC_URL" --timeout 20

# Transfer ownership (should be dropped)
cast send "$PHYLOCK_ADDRESS" \
  "transferOwnership(address)" 0x1234567890123456789012345678901234567890 \
  --private-key "$PRIVATE_KEY" \
  --rpc-url "$RPC_URL" \
  --timeout 20 \
  --gas-price 100000000000
```

### SimpleLending

Make sure your project includes both the lending contract and the price feed contract, then deploy:
- `SimpleLendingAssertion` for `SimpleLending`
- `PriceFeedAssertion` for the price feed

```bash
export PRIVATE_KEY=0x...
export LENDING_PROTOCOL=0x...
export TOKEN_ADDRESS=0x...
export PRICE_FEED=0x...
export RPC_URL=...

# Mint tokens to the lending protocol
cast send "$TOKEN_ADDRESS" "mint(address,uint256)" "$LENDING_PROTOCOL" 100000ether --private-key "$PRIVATE_KEY" --rpc-url "$RPC_URL"

# Deposit 0.5 ETH
cast send "$LENDING_PROTOCOL" "deposit()" --value 0.5ether --private-key "$PRIVATE_KEY" --rpc-url "$RPC_URL"

# Borrow 750 tokens
cast send "$LENDING_PROTOCOL" "borrow(uint256)" 750ether --private-key "$PRIVATE_KEY" --rpc-url "$RPC_URL"

# Withdraw collateral (should be dropped)
cast send "$LENDING_PROTOCOL" "withdraw(uint256)" 0.25ether --private-key "$PRIVATE_KEY" --rpc-url "$RPC_URL" --timeout 20

# Decrease price by 15% (should be dropped)
cast send "$PRICE_FEED" "setPrice(uint256)" 0.75ether --private-key "$PRIVATE_KEY" --rpc-url "$RPC_URL" --timeout 20 --gas-price 100000000000
```

## Additional Resources

- Quickstart: https://docs.phylax.systems/credible/pcl-quickstart
- Deploy with dApp: https://docs.phylax.systems/credible/deploy-assertions-dapp
- Assertions Book: https://docs.phylax.systems/assertions-book/assertions-book-intro
- Examples: https://github.com/phylaxsystems/assertions-examples
