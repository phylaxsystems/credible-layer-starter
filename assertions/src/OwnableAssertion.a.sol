// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {Ownable} from "../../src/Ownable.sol"; // Ownable contract

contract OwnableAssertion is Assertion {
    Ownable public ownable;

    // The triggers function tells the Credible Layer which assertion functions to run
    // This is required by the Assertion interface
    function triggers() external view override {
        // Register our assertion function to be called when transferOwnership is called
        registerCallTrigger(this.assertionOwnershipChange.selector, Ownable.transferOwnership.selector);
    }

    // This assertion checks if ownership has changed between pre and post transaction states
    function assertionOwnershipChange() external {
        // Get the adopter contract address using the cheatcode
        // This can be done instead of using the constructor and
        // is less error prone while storing and submitting the assertion
        ownable = Ownable(ph.getAssertionAdopter());

        // Create a snapshot of the blockchain state before the transaction
        ph.forkPreTx();

        // Get the owner before the transaction
        address preOwner = ownable.owner();

        // Create a snapshot of the blockchain state after the transaction
        ph.forkPostTx();

        // Get the owner after the transaction
        address postOwner = ownable.owner();

        // Assert that the owner hasn't changed
        // If this requirement fails, the assertion will revert
        require(postOwner == preOwner, "Ownership has changed");
    }
}
