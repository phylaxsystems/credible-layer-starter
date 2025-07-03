// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {CredibleTest} from "credible-std/CredibleTest.sol";
import {Test} from "forge-std/Test.sol";
import {ISupplier, Supplier} from "../src/DoubleCallInputBug.a.sol";
import {DoubleCallInputBug} from "../src/DoubleCallInputBug.a.sol";

contract DoubleCallInputBugTest is CredibleTest, Test {
    DoubleCallInputBug assertion;
    ISupplier supplier;
    string constant ASSERTION_LABEL = "MinimalPhEvmBug";
    address alice;

    function setUp() public {
        Supplier implementation = new Supplier();

        supplier = ISupplier(address(implementation));
        alice = makeAddr("alice");
    }

    function test_PhEvmDoubleCallIssue() public {
        cl.addAssertion(
            ASSERTION_LABEL, address(supplier), type(DoubleCallInputBug).creationCode, abi.encode(address(supplier))
        );

        vm.startPrank(alice);
        cl.validate(ASSERTION_LABEL, address(supplier), 0, abi.encodeWithSelector(supplier.supply.selector, 100));
    }
}
