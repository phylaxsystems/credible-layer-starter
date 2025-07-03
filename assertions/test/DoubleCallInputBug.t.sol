// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {CredibleTest} from "credible-std/CredibleTest.sol";
import {Test} from "forge-std/Test.sol";
import {Supplier} from "../src/DoubleCallInputBug.a.sol";
import {DoubleCallInputBug} from "../src/DoubleCallInputBug.a.sol";

/**
 * @title MinimalPhEvmBugTest
 * @notice Minimal test to reproduce PhEvm double-call issue
 * @dev This test demonstrates that ph.getCallInputs() reports 2 calls when only 1 is made
 */
contract DoubleCallInputBugTest is CredibleTest, Test {
    DoubleCallInputBug assertion;
    Supplier supplier;
    string constant ASSERTION_LABEL = "MinimalPhEvmBug";
    address alice;

    function setUp() public {
        supplier = new Supplier();
        alice = makeAddr("alice");

        // Deploy the minimal assertion
        assertion = new DoubleCallInputBug(supplier);
    }

    function test_PhEvmDoubleCallIssue() public {
        // Add assertion to the protocol
        cl.addAssertion(
            ASSERTION_LABEL, address(supplier), type(DoubleCallInputBug).creationCode, abi.encode(address(supplier))
        );

        vm.startPrank(alice);
        // This should pass since we only made 1 supply call
        // But it fails because PhEvm reports 2 calls
        cl.validate(ASSERTION_LABEL, address(supplier), 0, abi.encodeWithSelector(supplier.supply.selector, 100));
    }
}
