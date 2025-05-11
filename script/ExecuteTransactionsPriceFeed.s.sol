// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {MockTokenPriceFeed, IPriceFeed} from "../src/SimpleLending.sol";

contract BatchTokenPriceUpdates {
    IPriceFeed public tokenPriceFeed;

    constructor(address tokenPriceFeed_) {
        tokenPriceFeed = IPriceFeed(tokenPriceFeed_);
    }

    fallback() external {
        uint256 originalPrice = tokenPriceFeed.getPrice();

        // Perform 10 token price updates (using realistic token/USD prices)
        tokenPriceFeed.setPrice(0.95 ether); // $0.95
        tokenPriceFeed.setPrice(1.05 ether); // $1.05
        tokenPriceFeed.setPrice(0.9 ether); // $0.90
        tokenPriceFeed.setPrice(1.1 ether); // $1.10
        tokenPriceFeed.setPrice(0.85 ether); // $0.85 -- price deviates too much, should trigger assertion
        tokenPriceFeed.setPrice(1.15 ether); // $1.15
        tokenPriceFeed.setPrice(0.9 ether); // $0.90
        tokenPriceFeed.setPrice(originalPrice); // Return to original price
    }
}

contract ExecuteTransactionsPriceFeed is Script {
    // Configurable amounts
    uint256 constant INITIAL_PRICE = 1 ether; // $1.00
    uint256 constant SAFE_PRICE_INCREASE = 1.05 ether; // $1.05 (5% increase)
    uint256 constant UNSAFE_PRICE_DECREASE = 0.85 ether; // $0.85 (15% decrease)
    uint256 constant UNSAFE_PRICE_INCREASE = 1.15 ether; // $1.15 (15% increase)

    MockTokenPriceFeed priceFeed;
    address priceFeedAddress;

    constructor() {
        // Get price feed address from environment
        priceFeedAddress = vm.envAddress("PRICE_FEED");
    }

    function setUp() public {
        // Load private key from environment
        uint256 deployerPrivateKey = vm.envUint("PK_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);

        // Get the price feed interface
        priceFeed = MockTokenPriceFeed(priceFeedAddress);
        console2.log("Using price feed at: %s", priceFeedAddress);
    }

    function tearDown() public {
        vm.stopBroadcast();
    }

    function testSafePriceUpdate() public {
        console2.log("\n=== Testing Safe Price Update ===");
        console2.log("Current price: $%s", priceFeed.getPrice() / 1e18);
        console2.log("Queueing transaction to update price to $%s (5%% increase)...", SAFE_PRICE_INCREASE / 1e18);
        console2.log("This should succeed as it's within the allowed range");

        // This transaction will be executed after vm.stopBroadcast()
        priceFeed.setPrice(SAFE_PRICE_INCREASE);

        // Note: This log will appear before the transaction is actually executed
        console2.log(unicode"✅ Transaction queued successfully");
        console2.log("Note: The actual price update will occur when the transaction is mined");
    }

    function testUnsafePriceDecrease() public {
        console2.log("\n=== Testing Unsafe Price Decrease ===");
        console2.log("Current price: $%s", priceFeed.getPrice() / 1e18);
        console2.log("Queueing transaction to update price to $%s (15%% decrease)...", UNSAFE_PRICE_DECREASE / 1e18);
        console2.log("This should fail due to assertion: Price change exceeds 10%% threshold");

        // This transaction will be executed after vm.stopBroadcast()
        priceFeed.setPrice(UNSAFE_PRICE_DECREASE);

        // Note: This log will appear before the transaction is actually executed
        console2.log(unicode"❌ Transaction queued - will fail when executed");
    }

    function testUnsafePriceIncrease() public {
        console2.log("\n=== Testing Unsafe Price Increase ===");
        console2.log("Current price: $%s", priceFeed.getPrice() / 1e18);
        console2.log("Queueing transaction to update price to $%s (15%% increase)...", UNSAFE_PRICE_INCREASE / 1e18);
        console2.log("This should fail due to assertion: Price change exceeds 10%% threshold");

        // This transaction will be executed after vm.stopBroadcast()
        priceFeed.setPrice(UNSAFE_PRICE_INCREASE);

        // Note: This log will appear before the transaction is actually executed
        console2.log(unicode"❌ Transaction queued - will fail when executed");
    }

    function testBatchPriceUpdates() public {
        console2.log("\n=== Testing Batch Price Updates ===");
        console2.log("Current price: $%s", priceFeed.getPrice() / 1e18);
        console2.log("Queueing transaction to set initial price to $%s", INITIAL_PRICE / 1e18);

        // This transaction will be executed after vm.stopBroadcast()
        priceFeed.setPrice(INITIAL_PRICE);

        console2.log("Queueing deployment of batch updater contract...");
        // This deployment will be executed after vm.stopBroadcast()
        BatchTokenPriceUpdates batchUpdater = new BatchTokenPriceUpdates(priceFeedAddress);
        console2.log("Batch updater contract queued for deployment at: %s", address(batchUpdater));

        console2.log("Queueing batch updates with the following price changes:");
        console2.log("1. $0.95 (5% decrease)");
        console2.log("2. $1.05 (5% increase)");
        console2.log("3. $0.90 (10% decrease)");
        console2.log("4. $1.10 (10% increase)");
        console2.log("5. $0.85 (15% decrease) - Should trigger assertion");

        // This transaction will be executed after vm.stopBroadcast()
        (bool success,) = address(batchUpdater).call("");
        if (success) {
            console2.log(unicode"❌ Transaction queued - will fail when executed");
        }
    }
}

/*
To run this script:

1. Set up your environment variables:
   export PK_DEPLOYER=your_private_key
   export RPC_URL=your_rpc_url
   export PRICE_FEED=your_price_feed_address

2. Run individual test functions:
   # Test safe price update (should succeed)
   forge script script/ExecuteTransactionsPriceFeed.s.sol --sig "testSafePriceUpdate()" --rpc-url $RPC_URL --broadcast

   # Test unsafe price decrease (should timeout)
   forge script script/ExecuteTransactionsPriceFeed.s.sol --sig "testUnsafePriceDecrease()" --rpc-url $RPC_URL --broadcast

   # Test unsafe price increase (should timeout)
   forge script script/ExecuteTransactionsPriceFeed.s.sol --sig "testUnsafePriceIncrease()" --rpc-url $RPC_URL --broadcast

   # Test batch price updates (should timeout)
   forge script script/ExecuteTransactionsPriceFeed.s.sol --sig "testBatchPriceUpdates()" --rpc-url $RPC_URL --broadcast

Note: Before running:
1. Make sure you have sufficient ETH in your account
2. Make sure the price feed is properly deployed and initialized
3. Adjust the constant amounts if needed for your specific setup

Note about assertions:
- When an assertion fails, the transaction will timeout rather than revert
- You'll need to wait for the timeout period to see the result
- The console logs after the transaction call will only appear if the assertion doesn't trigger
*/
