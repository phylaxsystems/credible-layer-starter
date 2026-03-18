// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console2} from "forge-std/Script.sol";
import {DeployBase} from "./DeployBase.s.sol";
import {Ownable} from "../src/Ownable.sol";

contract DeployOwnable is DeployBase {
    Ownable public ownable;

    function run() public broadcast {
        console2.log("Deploying Ownable contract...");
        console2.log("Initial owner will be: %s", deployer);

        ownable = new Ownable(deployer);

        console2.log("Ownable deployed at: %s", address(ownable));
        console2.log("Initial owner set to: %s", ownable.owner());
    }
}
