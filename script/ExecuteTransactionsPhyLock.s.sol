// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {PhyLock} from "../src/PhyLock.sol";

contract ExecuteTransactionsPhyLock is Script {
    // Address of the deployed PhyLock contract
    address public phyLockAddress;

    function setUp() public {
        // Load the deployed contract address from environment
        phyLockAddress = vm.envAddress("PHYLOCK_ADDRESS");

        // Load private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
    }

    function tearDown() public {
        vm.stopBroadcast();
    }

    function deposit() public {
        // Get the PhyLock contract instance
        PhyLock phyLock = PhyLock(phyLockAddress);

        // Deposit 0.7 ETH from the caller
        phyLock.deposit{value: 0.7 ether}();

        console2.log("Attempting to deposit 0.7 ETH - should succeed");
    }

    function withdraw() public {
        // Get the PhyLock contract instance
        PhyLock phyLock = PhyLock(phyLockAddress);

        // Withdraw 0.2 ETH from the caller
        phyLock.withdraw(0.2 ether);

        console2.log("Attempting to withdraw 0.2 ETH - should succeed as user has sufficient deposit");
    }

    function withdrawWithoutDeposit() public {
        // Get the PhyLock contract instance
        PhyLock phyLock = PhyLock(phyLockAddress);

        // Try to withdraw 0.5 ETH without having a deposit
        // This will trigger the vulnerability in the contract
        phyLock.withdraw(0.5 ether);

        console2.log("Attempting to withdraw 0.2 ETH without deposit - should fail due to assertion protection");
    }

    function transferOwnership() public {
        // Get the PhyLock contract instance
        PhyLock phyLock = PhyLock(phyLockAddress);

        // Get the caller's address
        address caller = msg.sender;

        // Try to transfer ownership to the caller
        phyLock.transferOwnership(caller);

        console2.log("Attempting to transfer ownership to %s - should fail if caller is not owner", caller);
    }
}

/*
To run these scripts:

1. Set up your environment variables:
   # Note: Private key must be prefixed with 0x
   export PRIVATE_KEY=0x123...  # Your private key with 0x prefix
   export PHYLOCK_ADDRESS=0x456...  # Your deployed contract address
   export RPC_URL=your_rpc_url

2. Run individual functions using the --sig argument:

   # Deposit 0.7 ETH
   forge script script/ExecuteTransactionsPhyLock.s.sol --sig "deposit()" --rpc-url $RPC_URL --broadcast

   # Withdraw 0.2 ETH (happy path)
   forge script script/ExecuteTransactionsPhyLock.s.sol --sig "withdraw()" --rpc-url $RPC_URL --broadcast

   # Attempt to withdraw 0.5 ETH without a deposit (drain/exploit)
   # Use different address for the caller
   forge script script/ExecuteTransactionsPhyLock.s.sol --sig "withdrawWithoutDeposit()" --rpc-url $RPC_URL --broadcast

   # Attempt to transfer ownership to the caller
   forge script script/ExecuteTransactionsPhyLock.s.sol --sig "transferOwnership()" --rpc-url $RPC_URL --broadcast

Note:
- Make sure the caller has sufficient ETH for deposits/withdrawals and gas.
- The contract must be deployed and PHYLOCK_ADDRESS set.
- Each function is independent and can be called separately.
- Private key must be prefixed with 0x when setting the PRIVATE_KEY environment variable.
*/
