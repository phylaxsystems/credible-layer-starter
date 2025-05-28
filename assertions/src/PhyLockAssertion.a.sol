// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";
import {PhyLock} from "../../src/PhyLock.sol";

/// @title PhyLockAssertion
/// @notice Contract containing invariant assertions for the PhyLock contract
/// @dev These assertions verify that deposits and withdrawals maintain the expected state changes
contract PhyLockAssertion is Assertion {
    PhyLock phyLock;

    error PhyLockAssertion__DepositInvariantViolated(uint256 expectedChange, uint256 positionChangesSum, uint256 preBalance, uint256 postBalance, uint256 callsLength);


    constructor(address phyLock_) {
        phyLock = PhyLock(phyLock_);
    }
    

    /// @notice Registers which functions should trigger which assertions
    /// @dev Links deposit and withdraw functions to their respective invariant checks
    function triggers() external view override {
        registerCallTrigger(this.assertionWithdrawInvariant.selector, phyLock.withdraw.selector);
        registerCallTrigger(this.assertionDepositInvariant.selector, phyLock.deposit.selector);
    }

    /// @notice Verifies the deposit invariant
    /// @dev This assertion ensures that:
    /// 1. Total deposits never decrease after a deposit operation
    /// 2. The sum of individual deposit amounts matches the total deposit change
    /// 3. All deposit operations are properly accounted for
    function assertionDepositInvariant() external {
        // Capture the state before any deposits
        ph.forkPreState();
        uint256 preBalance = phyLock.totalDeposits();

        // Capture the state after deposits
        ph.forkPostState();
        uint256 postBalance = phyLock.totalDeposits();

        // Ensure deposits never decrease the total balance
        require(postBalance >= preBalance, "Deposit resulted in balance decrease");

        // Calculate the expected change in total deposits
        uint256 expectedChange = postBalance - preBalance;

        // Track the actual sum of deposit changes
        uint256 positionChangesSum = 0;

        // Get all deposit calls that occurred
        PhEvm.CallInputs[] memory calls = ph.getCallInputs(address(phyLock), phyLock.deposit.selector);

        // Sum up all individual deposit amounts
        for (uint256 i = 0; i < calls.length; i++) {
            uint256 amount = calls[i].value;
            positionChangesSum += amount;
        }

        // Verify that the sum of individual deposits matches the total change
        if (positionChangesSum != expectedChange) {
            revert PhyLockAssertion__DepositInvariantViolated(expectedChange, positionChangesSum, preBalance, postBalance, calls.length);
        }
    }

    /// @notice Verifies the withdraw invariant
    /// @dev This assertion ensures that:
    /// 1. Total deposits never increase after a withdrawal operation
    /// 2. The sum of remaining deposits matches the expected amount after withdrawals
    /// 3. All withdrawal operations are properly accounted for
    function assertionWithdrawInvariant() external {
        // Get all withdraw calls that occurred
        PhEvm.CallInputs[] memory calls = ph.getCallInputs(address(phyLock), phyLock.withdraw.selector);

        // Capture the state before any withdrawals
        ph.forkPreState();
        uint256 preBalance = phyLock.totalDeposits();

        // Calculate the sum of all positions before withdrawals
        uint256 prePositionChangesSum = 0;
        for (uint256 i = 0; i < calls.length; i++) {
            uint256 amount = phyLock.deposits(calls[i].caller);
            prePositionChangesSum += amount;
        }

        // Capture the state after withdrawals
        ph.forkPostState();
        uint256 postBalance = phyLock.totalDeposits();

        // Ensure withdrawals never increase the total balance
        require(postBalance <= preBalance, "Withdraw resulted in balance increase");

        // Calculate the expected change in total deposits
        uint256 expectedChange = preBalance - postBalance;

        // Calculate the sum of all positions after withdrawals
        uint256 postPositionChangesSum = 0;
        for (uint256 i = 0; i < calls.length; i++) {
            uint256 amount = phyLock.deposits(calls[i].caller);
            postPositionChangesSum += amount;
        }

        // Calculate the expected sum of positions after withdrawals
        uint256 expectedPositionChangesSum = prePositionChangesSum - postPositionChangesSum;

        // Verify that the sum of remaining positions matches the expected amount
        require(expectedChange == expectedPositionChangesSum, "Withdraw invariant violated");
    }
}
