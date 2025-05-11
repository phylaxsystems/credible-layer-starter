// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {SimpleLending} from "../src/SimpleLending.sol";
import {MockToken} from "./DeploySimpleLending.s.sol";

contract TestAssertionsScript is Script {
    // Configurable amounts
    uint256 constant UNSAFE_WITHDRAWAL_AMOUNT = 0.5 ether;
    uint256 constant SAFE_WITHDRAWAL_AMOUNT = 0.2 ether;
    uint256 constant DRAIN_ATTEMPT_AMOUNT = 8000 ether;
    uint256 constant NORMAL_WITHDRAWAL_AMOUNT = 800 ether;

    SimpleLending lending;
    MockToken token;
    address lendingProtocol;

    constructor() {
        // Get lending protocol address from environment
        lendingProtocol = vm.envAddress("LENDING_PROTOCOL");
        // Get token address from environment
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        token = MockToken(tokenAddress);
    }

    function setUp() public {
        // Load private key from environment
        uint256 deployerPrivateKey = vm.envUint("PK_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);

        // Mint tokens to the lending protocol
        token.mint(lendingProtocol, 1000000e18);

        // Get the lending protocol interface
        lending = SimpleLending(lendingProtocol);
        console2.log("Using lending protocol at: %s", lendingProtocol);
    }

    function tearDown() public {
        vm.stopBroadcast();
    }

    function testUnsafeWithdrawal() public {
        console2.log("Testing unsafe withdrawal scenario...");

        // User deposits 1 ETH as collateral
        lending.deposit{value: 1 ether}();
        console2.log("Deposited 1 ETH as collateral");

        // User borrows 1500 USDC (75% of collateral value at $2000/ETH)
        lending.borrow(1500e18);
        console2.log("Borrowed 1500 tokens (75% of collateral value)");

        console2.log("Attempting unsafe withdrawal of %s ETH...", UNSAFE_WITHDRAWAL_AMOUNT / 1e18);
        console2.log("This should timeout due to assertion failure");
        lending.withdraw(UNSAFE_WITHDRAWAL_AMOUNT);
        console2.log("If you see this, the assertion didn't trigger as expected");
    }

    function testSafeWithdrawal() public {
        console2.log("Testing safe withdrawal scenario...");

        // User deposits 1 ETH as collateral
        lending.deposit{value: 1 ether}();
        console2.log("Deposited 1 ETH as collateral");

        // User borrows only 500 USDC (25% of collateral value)
        lending.borrow(500e18);
        console2.log("Borrowed 500 tokens (25% of collateral value)");

        console2.log("Testing safe withdrawal of %s ETH...", SAFE_WITHDRAWAL_AMOUNT / 1e18);
        console2.log("This should succeed as it's a safe amount");
        lending.withdraw(SAFE_WITHDRAWAL_AMOUNT);
        console2.log("Transaction succeeded as expected");
    }

    function testProtocolDrain() public {
        console2.log("Testing protocol drain scenario...");

        // Setup multiple users depositing ETH
        address[] memory users = new address[](5);
        for (uint256 i = 0; i < 5; i++) {
            users[i] = address(uint160(0xbeef + i));

            // Direct deposit call
            lending.deposit{value: 2000 ether}();
            console2.log("User %d deposited 2000 ETH", i);
        }

        // Total protocol collateral is now 10000 ETH
        console2.log("Total protocol collateral: 10000 ETH");

        console2.log("Testing protocol drain attempt of %s ETH...", DRAIN_ATTEMPT_AMOUNT / 1e18);
        console2.log("This should timeout due to assertion failure");
        lending.buggyWithdraw(DRAIN_ATTEMPT_AMOUNT);
        console2.log("If you see this, the assertion didn't trigger as expected");
    }

    function testNormalWithdrawal() public {
        console2.log("Testing normal withdrawal scenario...");

        // Setup multiple users depositing ETH
        address[] memory users = new address[](5);
        for (uint256 i = 0; i < 5; i++) {
            users[i] = address(uint160(0xbeef + i));
            // Note: vm.deal is also a test utility, so we'll need to fund these addresses manually
            // or use a different approach for the script

            // Direct deposit call
            lending.deposit{value: 2000 ether}();
            console2.log("User %d deposited 2000 ETH", i);
        }

        console2.log("Testing normal withdrawal of %s ETH...", NORMAL_WITHDRAWAL_AMOUNT / 1e18);
        console2.log("This should succeed as it's a normal amount");
        lending.withdraw(NORMAL_WITHDRAWAL_AMOUNT);
        console2.log("Transaction succeeded as expected");
    }
}

/*
To run this script:

1. Set up your environment variables:
   export PK_DEPLOYER=your_private_key
   export RPC_URL=your_rpc_url
   export LENDING_PROTOCOL=your_lending_protocol_address
   export TOKEN_ADDRESS=your_token_address

2. Run individual test functions:
   # Test unsafe withdrawal (should timeout)
   forge script script/ExecuteTransactionsSimpleLending.s.sol --sig "testUnsafeWithdrawal()" --rpc-url $RPC_URL --broadcast

   # Test safe withdrawal (should succeed)
   forge script script/ExecuteTransactionsSimpleLending.s.sol --sig "testSafeWithdrawal()" --rpc-url $RPC_URL --broadcast

   # Test protocol drain (should timeout)
   forge script script/ExecuteTransactionsSimpleLending.s.sol --sig "testProtocolDrain()" --rpc-url $RPC_URL --broadcast

   # Test normal withdrawal (should succeed)
   forge script script/ExecuteTransactionsSimpleLending.s.sol --sig "testNormalWithdrawal()" --rpc-url $RPC_URL --broadcast

Note: Before running:
1. Make sure you have sufficient ETH and tokens in your account
2. Make sure you've deposited collateral before testing withdrawals
3. Adjust the constant amounts if needed for your specific setup

Note about assertions:
- When an assertion fails, the transaction will timeout rather than revert
- You'll need to wait for the timeout period to see the result
- The console logs after the transaction call will only appear if the assertion doesn't trigger
*/
