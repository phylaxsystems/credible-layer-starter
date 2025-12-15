// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {GasSpender} from "../../src/GasSpender.sol";

contract GasSpenderAssertion is Assertion {
    uint256 public result;

    function triggers() external view override {
        registerCallTrigger(this.assertion.selector, GasSpender.triggerAssertion.selector);
    }

    function assertion() external {
        GasSpender adopter = GasSpender(ph.getAssertionAdopter());

        uint256 counter = adopter.assertionCounter();

        uint256 tmp = 0;
        for(uint256 i = 0; i < counter; i++) {
            tmp++;
        }
        result = tmp;
    }
}
