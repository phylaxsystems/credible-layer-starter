// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";

contract ExecuteTransactionReset is Script {
    function run() public {
        // Load private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address sender = vm.addr(deployerPrivateKey);

        console2.log("Sender address: %s", sender);
        console2.log("Sending 0 ETH transaction to self with higher gas price...");

        // Start broadcasting with the private key
        vm.startBroadcast(deployerPrivateKey);

        // Send 0 ETH to self
        payable(sender).transfer(0);

        vm.stopBroadcast();

        console2.log("Transaction sent successfully");
    }
}

/*
To run this script:

1. Set up your environment variables:
   export PRIVATE_KEY=0x123...  # Your private key with 0x prefix
   export RPC_URL=your_rpc_url

2. Run the script with a higher gas price:
   forge script script/ExecuteTransactionReset.s.sol --rpc-url $RPC_URL --broadcast --gas-price 100000000000  # 100 gwei

Note: 
- Adjust the --gas-price parameter as needed for your network
- This script sends a 0 ETH transaction to your own address
- Useful for resolving "replacement transaction underpriced" errors
*/
