// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";

abstract contract DeployBase is Script {
    address public deployer;

    modifier broadcast() {
        deployer = vm.getWallets()[0];
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }
}
