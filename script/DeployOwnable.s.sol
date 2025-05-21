// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Ownable} from "../src/Ownable.sol";

contract DeployOwnable is Script {
    Ownable public ownable;

    function run() public {
        // Get deployer address from environment
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");

        console2.log("Deploying Ownable contract...");
        console2.log("Initial owner will be: %s", deployer);

        // Load private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy with deployer as initial owner
        ownable = new Ownable(deployer);

        vm.stopBroadcast();

        console2.log("Ownable deployed at: %s", address(ownable));
        console2.log("Initial owner set to: %s", ownable.owner());
    }
}

/*
To run this script:

1. Set up your environment variables:
   export DEPLOYER_ADDRESS=your_deployer_address
   export RPC_URL=your_rpc_url

2. Run the script:
   forge script script/DeployOwnable.s.sol --rpc-url $RPC_URL --broadcast

Note: The deployer address will be set as the initial owner
*/
