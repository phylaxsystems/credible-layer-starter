// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Ownable} from "../src/Ownable.sol";
import {OwnableAssertion} from "../assertions/src/OwnableAssertion.a.sol";

contract ExecuteTransactionsOwnable is Script {
    Ownable public ownable;
    address public initialOwner;
    address public newOwner;

    constructor() {
        // Get contract address from environment
        address ownableAddress = vm.envAddress("OWNABLE_ADDRESS");
        ownable = Ownable(ownableAddress);

        // Get owner addresses from environment
        initialOwner = vm.envAddress("DEPLOYER_ADDRESS");
        newOwner = vm.envAddress("NEW_OWNER");
    }

    function setUp() public {
        // Load private key from environment
        uint256 deployerPrivateKey = vm.envUint("PK_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
    }

    function testNoOwnershipChange() public {
        console2.log("\n=== Testing No Ownership Change ===");
        console2.log("Current owner: %s", ownable.owner());
        console2.log("Attempting to transfer ownership to current owner: %s", initialOwner);
        console2.log("This should succeed as it's not changing ownership");

        ownable.transferOwnership(initialOwner);

        console2.log(unicode"✅ Transaction succeeded as expected");
        console2.log("Owner remains: %s", ownable.owner());
    }

    function testOwnershipChange() public {
        console2.log("\n=== Testing Ownership Change ===");
        console2.log("Current owner: %s", ownable.owner());
        console2.log("Attempting to transfer ownership to: %s", newOwner);
        console2.log("This should fail due to assertion: Ownership changes are not allowed");

        ownable.transferOwnership(newOwner);

        console2.log(unicode"❌ If you see this, the assertion didn't trigger as expected");
    }
}

/*
To run this script:

1. Set up your environment variables:
   export PK_DEPLOYER=your_private_key
   export RPC_URL=your_rpc_url
   export OWNABLE_ADDRESS=your_ownable_contract_address
   export DEPLOYER_ADDRESS=your_deployer_address
   export NEW_OWNER=your_new_owner_address

2. Run individual test functions (recommended):
   # Test no ownership change (should succeed)
   forge script script/ExecuteTransactionsOwnable.s.sol --sig "testNoOwnershipChange()" --rpc-url $RPC_URL --broadcast

   # Test ownership change (should fail)
   forge script script/ExecuteTransactionsOwnable.s.sol --sig "testOwnershipChange()" --rpc-url $RPC_URL --broadcast

Note: Before running:
1. Make sure you have sufficient ETH in your account
2. Make sure the Ownable contract is properly deployed
3. Make sure the assertion is properly registered
4. Make sure you're using the correct owner addresses

Note: It's recommended to run the functions individually using --sig to ensure clean state for each test
*/
