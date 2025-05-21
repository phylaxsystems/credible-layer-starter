// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/PhyLock.sol";

contract DeployScript is Script {
    function run() public {
        // Load private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy PhyLock contract
        // Note: The PhylaxToken will be automatically deployed by the PhyLock constructor
        PhyLock phyLock = new PhyLock();
        console.log("PhyLock deployed at:", address(phyLock));
        console.log("PhylaxToken deployed at:", address(phyLock.phylaxToken()));

        vm.stopBroadcast();
    }
}
