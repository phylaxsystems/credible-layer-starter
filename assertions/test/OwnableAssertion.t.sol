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
        address aaAddress = address(assertionAdopter);
        string memory label = "Ownership has changed";

        // Associate the assertion with the protocol
        // cl will manage the correct assertion execution when the protocol is called
        cl.addAssertion(label, aaAddress, type(OwnableAssertion).creationCode, abi.encode(assertionAdopter));

        // Simulate a transaction that changes ownership
        vm.prank(initialOwner);
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            label, aaAddress, 0, abi.encodePacked(assertionAdopter.transferOwnership.selector, abi.encode(newOwner))
        );
    }

    // Test case: No ownership change should pass the assertion
    function test_assertionOwnershipNotChanged() public {
        string memory label = "Ownership has not changed";
        address aaAddress = address(assertionAdopter);

        cl.addAssertion(label, aaAddress, type(OwnableAssertion).creationCode, abi.encode(assertionAdopter));

        // Simulate a transaction that doesn't change ownership (transferring to same owner)
        vm.prank(initialOwner);
        cl.validate(
            label, aaAddress, 0, abi.encodePacked(assertionAdopter.transferOwnership.selector, abi.encode(initialOwner))
        );
    }
}
