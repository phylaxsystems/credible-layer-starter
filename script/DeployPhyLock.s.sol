// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {console} from "forge-std/Script.sol";
import {DeployBase} from "./DeployBase.s.sol";
import "../src/PhyLock.sol";

contract DeployScript is DeployBase {
    function run() public broadcast {
        PhyLock phyLock = new PhyLock();
        console.log("PhyLock deployed at:", address(phyLock));
        console.log("PhylaxToken deployed at:", address(phyLock.phylaxToken()));
    }
}
