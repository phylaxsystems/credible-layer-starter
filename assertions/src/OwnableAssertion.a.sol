// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol"; // Using remapping for credible-std
import {Ownable} from "../../src/Ownable.sol"; // Ownable contract

contract OwnableAssertion is Assertion {
    // The contract we're monitoring
    Ownable ownable;

    // Constructor takes the address of the contract to monitor
    constructor(address ownable_) {
        ownable = Ownable(ownable_); // Initialize the Ownable contract reference
    }

    // The triggers function tells the Credible Layer which assertion functions to run
    // This is required by the Assertion interface
    function triggers() external view override {
        // Register our assertion function to be called when transactions interact with the Ownable contract
        registerCallTrigger(this.assertionOwnershipChange.selector);
    }

    // This assertion checks if ownership has changed between pre and post transaction states
    function assertionOwnershipChange() external {
        // Create a snapshot of the blockchain state before the transaction
        ph.forkPreState();

        // Get the owner before the transaction
        address preOwner = ownable.owner();

        // Create a snapshot of the blockchain state after the transaction
        ph.forkPostState();

        // Get the owner after the transaction
        address postOwner = ownable.owner();

        // Assert that the owner hasn't changed
        // If this requirement fails, the assertion will revert
        require(postOwner == preOwner, "Ownership has changed");
    }
}
