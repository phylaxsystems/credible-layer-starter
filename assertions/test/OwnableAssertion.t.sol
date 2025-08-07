// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OwnableAssertion} from "../src/OwnableAssertion.a.sol";
import {Ownable} from "../../src/Ownable.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {Test} from "forge-std/Test.sol";

contract TestOwnableAssertion is CredibleTest, Test {
    // Contract state variables
    Ownable public assertionAdopter;
    address public initialOwner = address(0xf00);
    address public newOwner = address(0xdeadbeef);

    // Set up the test environment
    function setUp() public {
        assertionAdopter = new Ownable(initialOwner);
        vm.deal(initialOwner, 1 ether);
    }

    // Test case: Ownership changes should trigger the assertion
    function test_assertionOwnershipChanged() public {
        assertEq(assertionAdopter.owner(), initialOwner);

        cl.assertion({
            adopter: address(assertionAdopter),
            createData: type(OwnableAssertion).creationCode,
            fnSelector: OwnableAssertion.assertionOwnershipChange.selector
        });

        // Simulate a transaction that changes ownership
        vm.prank(initialOwner);
        vm.expectRevert("Ownership has changed");
        assertionAdopter.transferOwnership(newOwner);

        // Check that owner didn't change
        assertEq(assertionAdopter.owner(), initialOwner);
    }

    // Test case: No ownership change should pass the assertion
    function test_assertionOwnershipNotChanged() public {
        cl.assertion({
            adopter: address(assertionAdopter),
            createData: type(OwnableAssertion).creationCode,
            fnSelector: OwnableAssertion.assertionOwnershipChange.selector
        });

        // Simulate a transaction that doesn't change ownership (transferring to same owner)
        vm.prank(initialOwner);
        assertionAdopter.transferOwnership(initialOwner);
    }
}
