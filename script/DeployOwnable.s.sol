// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Ownable} from "../src/Ownable.sol";

contract DeployOwnable is Script {
    Ownable public ownable;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        ownable = new Ownable();

        vm.stopBroadcast();
    }
}