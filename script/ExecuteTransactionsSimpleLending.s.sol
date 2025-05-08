// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {SimpleLending} from "../src/SimpleLending.sol";

contract TestAssertionsScript is Script {
    // Configurable amounts
    uint256 constant UNSAFE_WITHDRAWAL_AMOUNT = 0.5 ether;
    uint256 constant SAFE_WITHDRAWAL_AMOUNT = 0.2 ether;
    uint256 constant DRAIN_ATTEMPT_AMOUNT = 8000 ether;
    uint256 constant NORMAL_WITHDRAWAL_AMOUNT = 800 ether;

    SimpleLending lending;
    address lendingProtocol;

    constructor() {
        // Get lending protocol address from environment or use default
        lendingProtocol = vm.envOr("LENDING_PROTOCOL", address(0x1234));
    }

    function setUp() public {
        // Load private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Get the lending protocol interface
        lending = SimpleLending(lendingProtocol);
        console2.log("Using lending protocol at: %s", lendingProtocol);
    }

    function tearDown() public {
        vm.stopBroadcast();
    }

    function testUnsafeWithdrawal() public {
        setUp();
        console2.log("Testing unsafe withdrawal of %s ETH...", UNSAFE_WITHDRAWAL_AMOUNT / 1e18);
        console2.log("This should timeout due to assertion failure");
        lending.withdraw(UNSAFE_WITHDRAWAL_AMOUNT);
        console2.log("If you see this, the assertion didn't trigger as expected");
        tearDown();
    }

    function testSafeWithdrawal() public {
        setUp();
        console2.log("Testing safe withdrawal of %s ETH...", SAFE_WITHDRAWAL_AMOUNT / 1e18);
        console2.log("This should succeed as it's a safe amount");
        lending.withdraw(SAFE_WITHDRAWAL_AMOUNT);
        console2.log("Transaction succeeded as expected");
        tearDown();
    }

    function testProtocolDrain() public {
        setUp();
        console2.log("Testing protocol drain attempt of %s ETH...", DRAIN_ATTEMPT_AMOUNT / 1e18);
        console2.log("This should timeout due to assertion failure");
        lending.buggyWithdraw(DRAIN_ATTEMPT_AMOUNT);
        console2.log("If you see this, the assertion didn't trigger as expected");
        tearDown();
    }

    function testNormalWithdrawal() public {
        setUp();
        console2.log("Testing normal withdrawal of %s ETH...", NORMAL_WITHDRAWAL_AMOUNT / 1e18);
        console2.log("This should succeed as it's a normal amount");
        lending.withdraw(NORMAL_WITHDRAWAL_AMOUNT);
        console2.log("Transaction succeeded as expected");
        tearDown();
    }

    function run() public {
        setUp();

        // Run all test scenarios
        testUnsafeWithdrawal();
        testSafeWithdrawal();
        testProtocolDrain();
        testNormalWithdrawal();

        tearDown();
    }
}

/*
To run this script:

1. Set up your environment variables:
   export PRIVATE_KEY=your_private_key
   export RPC_URL=your_rpc_url
   export LENDING_PROTOCOL=your_lending_protocol_address  # Optional, will use default if not set

2. Run the entire script:
   forge script script/TestAssertions.s.sol --rpc-url $RPC_URL --broadcast

3. Run individual test functions:
   # Test unsafe withdrawal (should timeout)
   forge script script/TestAssertions.s.sol --sig "testUnsafeWithdrawal()" --rpc-url $RPC_URL --broadcast

   # Test safe withdrawal (should succeed)
   forge script script/TestAssertions.s.sol --sig "testSafeWithdrawal()" --rpc-url $RPC_URL --broadcast

   # Test protocol drain (should timeout)
   forge script script/TestAssertions.s.sol --sig "testProtocolDrain()" --rpc-url $RPC_URL --broadcast

   # Test normal withdrawal (should succeed)
   forge script script/TestAssertions.s.sol --sig "testNormalWithdrawal()" --rpc-url $RPC_URL --broadcast

Note: Before running:
1. Make sure you have sufficient ETH and tokens in your account
2. Make sure you've deposited collateral before testing withdrawals
3. Adjust the constant amounts if needed for your specific setup

Note about assertions:
- When an assertion fails, the transaction will timeout rather than revert
- You'll need to wait for the timeout period to see the result
- The console logs after the transaction call will only appear if the assertion doesn't trigger
*/
