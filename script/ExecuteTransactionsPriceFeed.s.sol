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
        // Get price feed address from environment or use default
        priceFeedAddress = vm.envOr("PRICE_FEED", address(0x1234));
    }

    function setUp() public {
        // Load private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Get the price feed interface
        priceFeed = MockTokenPriceFeed(priceFeedAddress);
        console2.log("Using price feed at: %s", priceFeedAddress);
    }

    function tearDown() public {
        vm.stopBroadcast();
    }

    function testSafePriceUpdate() public {
        setUp();
        console2.log("Testing safe price update to %s USD...", SAFE_PRICE_INCREASE / 1e18);
        console2.log("This should succeed as it's within the allowed range");
        priceFeed.setPrice(SAFE_PRICE_INCREASE);
        console2.log("Price update succeeded as expected");
        tearDown();
    }

    function testUnsafePriceDecrease() public {
        setUp();
        console2.log("Testing unsafe price decrease to %s USD...", UNSAFE_PRICE_DECREASE / 1e18);
        console2.log("This should timeout due to assertion failure");
        priceFeed.setPrice(UNSAFE_PRICE_DECREASE);
        console2.log("If you see this, the assertion didn't trigger as expected");
        tearDown();
    }

    function testUnsafePriceIncrease() public {
        setUp();
        console2.log("Testing unsafe price increase to %s USD...", UNSAFE_PRICE_INCREASE / 1e18);
        console2.log("This should timeout due to assertion failure");
        priceFeed.setPrice(UNSAFE_PRICE_INCREASE);
        console2.log("If you see this, the assertion didn't trigger as expected");
        tearDown();
    }

    function testBatchPriceUpdates() public {
        setUp();
        console2.log("Testing batch price updates...");
        console2.log("This should timeout due to assertion failure");

        // Set initial price
        priceFeed.setPrice(INITIAL_PRICE);

        // Deploy the batch updater contract
        BatchTokenPriceUpdates batchUpdater = new BatchTokenPriceUpdates(priceFeedAddress);

        // Execute the batch updates in a single transaction
        (bool success,) = address(batchUpdater).call("");
        if (success) {
            console2.log("If you see this, the assertion didn't trigger as expected");
        }

        tearDown();
    }

    function run() public {
        setUp();

        // Run all test scenarios
        testSafePriceUpdate();
        testUnsafePriceDecrease();
        testUnsafePriceIncrease();
        testBatchPriceUpdates();

        tearDown();
    }
}

/*
To run this script:

1. Set up your environment variables:
   export PRIVATE_KEY=your_private_key
   export RPC_URL=your_rpc_url
   export PRICE_FEED=your_price_feed_address  # Optional, will use default if not set

2. Run the entire script:
   forge script script/ExecuteTransactionsPriceFeed.s.sol --rpc-url $RPC_URL --broadcast

3. Run individual test functions:
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
