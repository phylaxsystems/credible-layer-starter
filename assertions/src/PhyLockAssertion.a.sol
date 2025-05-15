// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";
import {PhyLock} from "../../src/PhyLock.sol";

contract PhyLockAssertion is Assertion {
    PhyLock phyLock;

    constructor(address phyLock_) {
        phyLock = PhyLock(phyLock_);
    }

    function triggers() external view override {
        registerCallTrigger(this.assertionWithdrawInvariant.selector, phyLock.withdraw.selector);
        registerCallTrigger(this.assertionDepositInvariant.selector, phyLock.deposit.selector);
    }

    function assertionDepositInvariant() external {
        ph.forkPreState();

        uint256 preBalance = phyLock.totalDeposits();

        ph.forkPostState();

        uint256 postBalance = phyLock.totalDeposits();

        require(postBalance >= preBalance, "Deposit resulted in balance decrease");

        // Calculate the expected change in total deposits
        uint256 expectedChange = postBalance - preBalance;

        // Track the actual sum of deposit changes
        uint256 positionChangesSum = 0;

        PhEvm.CallInputs[] memory calls = ph.getCallInputs(address(phyLock), phyLock.deposit.selector);

        for (uint256 i = 0; i < calls.length; i++) {
            uint256 amount = calls[i].value;

            positionChangesSum += amount;
        }

        require(positionChangesSum == expectedChange, "Deposit invariant violated");
    }

    function assertionWithdrawInvariant() external {
        PhEvm.CallInputs[] memory calls = ph.getCallInputs(address(phyLock), phyLock.withdraw.selector);

        ph.forkPreState();

        uint256 preBalance = phyLock.totalDeposits();

        uint256 prePositionChangesSum = 0;
        for (uint256 i = 0; i < calls.length; i++) {
            uint256 amount = phyLock.deposits(calls[i].caller);
            prePositionChangesSum += amount;
        }

        ph.forkPostState();

        uint256 postBalance = phyLock.totalDeposits();

        require(postBalance <= preBalance, "Withdraw resulted in balance increase");

        uint256 expectedChange = preBalance - postBalance;

        uint256 postPositionChangesSum = 0;

        for (uint256 i = 0; i < calls.length; i++) {
            uint256 amount = phyLock.deposits(calls[i].caller);

            postPositionChangesSum += amount;
        }

        uint256 expectedPositionChangesSum = prePositionChangesSum - expectedChange;

        require(postPositionChangesSum == expectedPositionChangesSum, "Withdraw invariant violated");
    }
}
