// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {GasSpenderAssertion} from "../src/GasSpenderAssertion.a.sol";
import {GasSpender} from "../../src/GasSpender.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {Test} from "forge-std/Test.sol";

contract GasSpenderAssertionTest is CredibleTest, Test {
    // Contract state variables
    GasSpender public assertionAdopter;

    // Set up the test environment
    function setUp() public {
        assertionAdopter = new GasSpender();
    }

    function test_assertion() public {
        cl.assertion({
            adopter: address(assertionAdopter),
            createData: type(GasSpenderAssertion).creationCode,
            fnSelector: GasSpenderAssertion.assertion.selector
        });

        assertionAdopter.triggerAssertion(100, 100);
    }

}
