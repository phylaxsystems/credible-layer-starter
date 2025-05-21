// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {PhyLockAssertion} from "../src/PhyLockAssertion.a.sol";
import {PhyLock} from "../../src/PhyLock.sol";

contract TestPhyLockAssertion is CredibleTest, Test {
    PhyLock public assertionAdopter;
    PhyLockAssertion public assertion;

    address user1 = address(0xBEEF);
    address user2 = address(0xCAFE);
    address user3 = address(0xDEAD);

    function setUp() public {
        // Deploy the PhyLock contract
        assertionAdopter = new PhyLock();

        // Deploy the assertion
        assertion = new PhyLockAssertion(address(assertionAdopter));

        // Setup test users with ETH
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);

        // Make initial deposits from multiple users
        vm.prank(user1);
        assertionAdopter.deposit{value: 5 ether}();

        vm.prank(user2);
        assertionAdopter.deposit{value: 3 ether}();

        vm.prank(user3);
        assertionAdopter.deposit{value: 2 ether}();
    }

    function testAssertionAllowsValidDeposit() public {
        // Register the assertion
        cl.addAssertion(
            "PhyLockAssertion",
            address(assertionAdopter),
            type(PhyLockAssertion).creationCode,
            abi.encode(address(assertionAdopter))
        );

        // Try to deposit 1 ETH - this should succeed
        vm.prank(user1);
        cl.validate(
            "PhyLockAssertion",
            address(assertionAdopter),
            1 ether,
            abi.encodeWithSelector(assertionAdopter.deposit.selector)
        );
    }

    function testAssertionAllowsValidWithdrawal() public {
        // Register the assertion
        cl.addAssertion(
            "PhyLockAssertion",
            address(assertionAdopter),
            type(PhyLockAssertion).creationCode,
            abi.encode(address(assertionAdopter))
        );

        // Execute and validate the withdrawal
        vm.prank(user1);
        cl.validate(
            "PhyLockAssertion",
            address(assertionAdopter),
            0,
            abi.encodeWithSelector(assertionAdopter.withdraw.selector, 2 ether)
        );
    }

    function testAssertionAllowsFullWithdrawal() public {
        // Register the assertion
        cl.addAssertion(
            "PhyLockAssertion",
            address(assertionAdopter),
            type(PhyLockAssertion).creationCode,
            abi.encode(address(assertionAdopter))
        );

        // Execute and validate the withdrawal
        vm.prank(user1);
        cl.validate(
            "PhyLockAssertion",
            address(assertionAdopter),
            0,
            abi.encodeWithSelector(assertionAdopter.withdraw.selector, 5 ether)
        );
    }

    function testAssertionCatchesZeroDepositWithdrawal() public {
        // Register the assertion
        cl.addAssertion(
            "PhyLockAssertion",
            address(assertionAdopter),
            type(PhyLockAssertion).creationCode,
            abi.encode(address(assertionAdopter))
        );

        address userWithNoDeposit = address(0xBEEF1);
        vm.deal(userWithNoDeposit, 1 ether);

        // Try to withdraw with zero deposit - this should revert the assertion
        vm.prank(userWithNoDeposit);
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            "PhyLockAssertion",
            address(assertionAdopter),
            0,
            abi.encodeWithSelector(assertionAdopter.withdraw.selector, 10 ether)
        );
    }

    function testDelayedZeroDepositWithdrawal() public {
        // Register the assertion
        cl.addAssertion(
            "PhyLockAssertion",
            address(assertionAdopter),
            type(PhyLockAssertion).creationCode,
            abi.encode(address(assertionAdopter))
        );

        // Fast forward 10 blocks to accumulate rewards
        vm.roll(block.number + 10);

        address userWithNoDeposit = address(0xBEEF1);
        vm.deal(userWithNoDeposit, 1 ether);

        // Try to withdraw with zero deposit - this should revert the assertion
        vm.prank(userWithNoDeposit);
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            "PhyLockAssertion",
            address(assertionAdopter),
            0,
            abi.encodeWithSelector(assertionAdopter.withdraw.selector, 10 ether)
        );
    }

    function testRewardsCalculationAndDistribution() public {
        // Get the initial token balance
        uint256 initialTokenBalance = assertionAdopter.phylaxToken().balanceOf(user1);

        // Record initial deposit amount
        uint256 depositAmount = assertionAdopter.deposits(user1);
        console.log("Initial user1 deposit:", depositAmount);

        // Fast forward 10 blocks to accumulate rewards
        uint256 blocksToMine = 10;
        vm.roll(block.number + blocksToMine);

        // Calculate expected rewards
        // Formula: blocksStaked * REWARD_RATE * depositAmount
        uint256 expectedRewards = blocksToMine * assertionAdopter.REWARD_RATE() * depositAmount;
        console.log("Expected rewards:", expectedRewards);

        // Trigger rewards distribution by making a small deposit
        vm.prank(user1);
        assertionAdopter.deposit{value: 0.1 ether}();

        // Check the new token balance
        uint256 newTokenBalance = assertionAdopter.phylaxToken().balanceOf(user1);
        console.log("Actual rewards:", newTokenBalance - initialTokenBalance);

        // Assert that the actual rewards match the expected rewards
        assertEq(newTokenBalance - initialTokenBalance, expectedRewards, "Rewards calculation is incorrect");

        // Now test withdrawal with rewards
        uint256 preWithdrawTokenBalance = newTokenBalance;

        // Fast forward another 5 blocks
        vm.roll(block.number + 5);

        // Calculate expected rewards for this period
        // New deposit amount is depositAmount + 0.1 ether
        uint256 newDepositAmount = assertionAdopter.deposits(user1);
        uint256 additionalExpectedRewards = 5 * assertionAdopter.REWARD_RATE() * newDepositAmount;

        // Withdraw half of the deposit
        uint256 withdrawAmount = newDepositAmount / 2;
        vm.prank(user1);
        assertionAdopter.withdraw(withdrawAmount);

        // Check final token balance
        uint256 finalTokenBalance = assertionAdopter.phylaxToken().balanceOf(user1);
        console.log("Additional rewards from withdrawal:", finalTokenBalance - preWithdrawTokenBalance);

        // Assert additional rewards
        assertEq(
            finalTokenBalance - preWithdrawTokenBalance,
            additionalExpectedRewards,
            "Withdrawal rewards calculation is incorrect"
        );
    }

    function testBasicWithdrawal() public {
        uint256 initialBalance = user1.balance;
        uint256 initialDeposit = assertionAdopter.deposits(user1);

        vm.prank(user1);
        assertionAdopter.withdraw(2 ether);

        assertEq(assertionAdopter.deposits(user1), initialDeposit - 2 ether, "Deposit amount not updated correctly");
        assertEq(user1.balance, initialBalance + 2 ether, "User balance not updated correctly");
    }

    function testMultipleWithdrawals() public {
        uint256 initialBalance = user1.balance;
        uint256 initialDeposit = assertionAdopter.deposits(user1);

        // First withdrawal
        vm.prank(user1);
        assertionAdopter.withdraw(1 ether);

        // Second withdrawal
        vm.prank(user1);
        assertionAdopter.withdraw(2 ether);

        assertEq(
            assertionAdopter.deposits(user1),
            initialDeposit - 3 ether,
            "Deposit amount not updated correctly after multiple withdrawals"
        );
        assertEq(
            user1.balance, initialBalance + 3 ether, "User balance not updated correctly after multiple withdrawals"
        );
    }

    function testWithdrawalUpdatesTotalDeposits() public {
        uint256 initialTotalDeposits = assertionAdopter.totalDeposits();

        vm.prank(user1);
        assertionAdopter.withdraw(2 ether);

        assertEq(
            assertionAdopter.totalDeposits(), initialTotalDeposits - 2 ether, "Total deposits not updated correctly"
        );
    }

    function testWithdrawalWithRewards() public {
        // Fast forward 10 blocks to accumulate rewards
        vm.roll(block.number + 10);

        uint256 initialDeposit = assertionAdopter.deposits(user1);
        uint256 initialTotalDeposits = assertionAdopter.totalDeposits();
        uint256 initialTokenBalance = assertionAdopter.phylaxToken().balanceOf(user1);

        // Register the assertion
        cl.addAssertion(
            "PhyLockAssertion",
            address(assertionAdopter),
            type(PhyLockAssertion).creationCode,
            abi.encode(address(assertionAdopter))
        );

        // Execute withdrawal
        vm.prank(user1);
        assertionAdopter.withdraw(2 ether);

        // Verify state changes
        assertEq(assertionAdopter.deposits(user1), initialDeposit - 2 ether, "User deposit not updated correctly");
        assertEq(
            assertionAdopter.totalDeposits(), initialTotalDeposits - 2 ether, "Total deposits not updated correctly"
        );

        // Verify rewards were distributed
        uint256 newTokenBalance = assertionAdopter.phylaxToken().balanceOf(user1);
        assertTrue(newTokenBalance > initialTokenBalance, "No rewards were distributed");
    }

    function testContractBalanceAfterWithdrawal() public {
        uint256 initialContractBalance = address(assertionAdopter).balance;
        uint256 withdrawalAmount = 2 ether;

        vm.prank(user1);
        assertionAdopter.withdraw(withdrawalAmount);

        assertEq(
            address(assertionAdopter).balance,
            initialContractBalance - withdrawalAmount,
            "Contract balance not updated correctly after withdrawal"
        );
    }

    function testContractBalanceAfterMultipleWithdrawals() public {
        uint256 initialContractBalance = address(assertionAdopter).balance;

        // First withdrawal
        vm.prank(user1);
        assertionAdopter.withdraw(1 ether);

        // Second withdrawal from different user
        vm.prank(user2);
        assertionAdopter.withdraw(1 ether);

        assertEq(
            address(assertionAdopter).balance,
            initialContractBalance - 2 ether,
            "Contract balance not updated correctly after multiple withdrawals"
        );
    }

    function testContractBalanceAfterFullWithdrawal() public {
        uint256 initialContractBalance = address(assertionAdopter).balance;
        uint256 user1Deposit = assertionAdopter.deposits(user1);

        vm.prank(user1);
        assertionAdopter.withdraw(user1Deposit);

        assertEq(
            address(assertionAdopter).balance,
            initialContractBalance - user1Deposit,
            "Contract balance not updated correctly after full withdrawal"
        );
    }

    function testContractBalanceWithRewards() public {
        uint256 initialContractBalance = address(assertionAdopter).balance;

        // Fast forward to accumulate rewards
        vm.roll(block.number + 10);

        vm.prank(user1);
        assertionAdopter.withdraw(2 ether);

        // Contract balance should only decrease by withdrawal amount, not by rewards
        assertEq(
            address(assertionAdopter).balance,
            initialContractBalance - 2 ether,
            "Contract balance not updated correctly with rewards"
        );
    }
}
