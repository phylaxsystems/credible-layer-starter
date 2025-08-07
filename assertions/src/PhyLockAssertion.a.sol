// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";
import {PhyLock} from "../../src/PhyLock.sol";

/// @title PhyLockAssertion
/// @notice Contract containing invariant assertions for the PhyLock contract
/// @dev These assertions verify that deposits and withdrawals maintain the expected state changes
contract PhyLockAssertion is Assertion {
    /// @notice Registers which functions should trigger which assertions
    /// @dev Links deposit and withdraw functions to their respective invariant checks
    function triggers() external view override {
        registerCallTrigger(this.assertionWithdrawInvariant.selector, PhyLock.withdraw.selector);
        registerCallTrigger(this.assertionDepositInvariant.selector, PhyLock.deposit.selector);
    }

    /// @notice Verifies the deposit invariant
    /// @dev This assertion ensures that:
    /// 1. Total deposits never decrease after a deposit operation
    /// 2. The sum of individual deposit amounts matches the total deposit change
    /// 3. All deposit operations are properly accounted for
    function assertionDepositInvariant() external {
        PhyLock phyLock = PhyLock(ph.getAssertionAdopter());
        // Capture the state before any deposits
        ph.forkPreTx();
        uint256 preBalance = phyLock.totalDeposits();

        // Capture the state after deposits
        ph.forkPostTx();
        uint256 postBalance = phyLock.totalDeposits();

        // Ensure deposits never decrease the total balance
        require(postBalance >= preBalance, "Deposit resulted in balance decrease");

        // Calculate the expected change in total deposits
        uint256 expectedChange = postBalance - preBalance;

        // Track the actual sum of deposit changes
        uint256 positionChangesSum = 0;

        // Get all deposit calls that occurred
        PhEvm.CallInputs[] memory calls = ph.getCallInputs(address(phyLock), PhyLock.deposit.selector);

        // Sum up all individual deposit amounts
        for (uint256 i = 0; i < calls.length; i++) {
            uint256 amount = calls[i].value;
            positionChangesSum += amount;
        }

        // Verify that the sum of individual deposits matches the total change
        require(positionChangesSum == expectedChange, "Deposit invariant violated");
    }

    /// @notice Verifies the withdraw invariant
    /// @dev This assertion ensures that:
    /// 1. Total deposits never increase after a withdrawal operation
    /// 2. The sum of remaining deposits matches the expected amount after withdrawals
    /// 3. All withdrawal operations are properly accounted for
    function assertionWithdrawInvariant() external {
        PhyLock phyLock = PhyLock(ph.getAssertionAdopter());

        // Get all withdraw calls that occurred
        PhEvm.CallInputs[] memory calls = ph.getCallInputs(address(phyLock), PhyLock.withdraw.selector);

        // Capture the state before any withdrawals
        ph.forkPreTx();
        uint256 preBalance = phyLock.totalDeposits();

        // Capture the state after withdrawals
        ph.forkPostTx();
        uint256 postBalance = phyLock.totalDeposits();

        // Ensure withdrawals never increase the total balance
        require(postBalance <= preBalance, "Withdraw resulted in balance increase");

        // Calculate the expected change in total deposits
        uint256 expectedChange = preBalance - postBalance;

        // Calculate the sum of all withdraw calls
        uint256 withdrawAmountSum = 0;
        uint256 prePositionChangesSum = 0;
        uint256 postPositionChangesSum = 0;
        for (uint256 i = 0; i < calls.length; i++) {
            ph.forkPreTx();
            uint256 callerPreBalance = phyLock.deposits(calls[i].caller);
            prePositionChangesSum += callerPreBalance;

            ph.forkPostTx();
            uint256 amount = abi.decode(calls[i].input, (uint256));
            withdrawAmountSum += amount;

            uint256 callerPostBalance = phyLock.deposits(calls[i].caller);
            postPositionChangesSum += callerPostBalance;
            // Explicitly fail if the caller withdraws more than they have deposited instead of relying on arithmetic error
            require(amount <= callerPreBalance, "Caller withdraw amount higher than deposit");
            require(callerPostBalance == callerPreBalance - amount, "Caller withdraw amount mismatch");
        }

        // Calculate the expected sum of positions after withdrawals
        uint256 expectedPositionChangesSum = prePositionChangesSum - postPositionChangesSum;

        // Verify that the sum of remaining positions matches the expected amount
        require(expectedChange == expectedPositionChangesSum, "Withdraw invariant violated");

        // Verify that the sum of withdraw amounts matches the actual total balance change
        require(withdrawAmountSum == expectedChange, "Withdraw amount sum mismatch");
    }
}
