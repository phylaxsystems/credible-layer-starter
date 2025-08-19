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
        assertion = new PhyLockAssertion();

        // Setup test users with ETH
        vm.deal(user1, 100 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);

        // Make initial deposits from multiple users
        vm.prank(user1);
        assertionAdopter.deposit{value: 5 ether}();

        vm.prank(user2);
        assertionAdopter.deposit{value: 5 ether}();
    }

    function testAssertionAllowsValidDeposit() public {
        assertEq(assertionAdopter.deposits(user1), 5 ether);
        // Setup assertion for next transaction
        cl.assertion({
            adopter: address(assertionAdopter),
            createData: type(PhyLockAssertion).creationCode,
            fnSelector: PhyLockAssertion.assertionDepositInvariant.selector
        });

        // Try to deposit 1 ETH - this should succeed
        vm.prank(user1);
        assertionAdopter.deposit{value: 1 ether}();

        // State changes in the assertion trigger are now persisted
        assertEq(assertionAdopter.deposits(user1), 6 ether);
    }

    function testAssertionAllowsValidWithdrawal() public {
        assertEq(assertionAdopter.deposits(user1), 5 ether);
        // Setup assertion for next transaction
        cl.assertion({
            adopter: address(assertionAdopter),
            createData: type(PhyLockAssertion).creationCode,
            fnSelector: PhyLockAssertion.assertionWithdrawInvariant.selector
        });

        // Execute withdrawal - this should succeed
        vm.prank(user1);
        assertionAdopter.withdraw(2 ether);

        assertEq(assertionAdopter.deposits(user1), 3 ether);
    }

    function testAssertionAllowsFullWithdrawal() public {
        assertEq(assertionAdopter.deposits(user1), 5 ether);
        // Setup assertion for next transaction
        cl.assertion({
            adopter: address(assertionAdopter),
            createData: type(PhyLockAssertion).creationCode,
            fnSelector: PhyLockAssertion.assertionWithdrawInvariant.selector
        });

        // Execute full withdrawal - this should succeed
        vm.prank(user1);
        assertionAdopter.withdraw(5 ether);
    }

    // TODO: delete this test, just here for testing ci/cd
    function test_ci_cd() public {
        assertEq(assertionAdopter.deposits(user1), 5 ether);
    }

    function testAssertionCatchesMagicNumberDrain() public {
        assertEq(assertionAdopter.deposits(user1), 5 ether);
        // Setup assertion for next transaction
        cl.assertion({
            adopter: address(assertionAdopter),
            createData: type(PhyLockAssertion).creationCode,
            fnSelector: PhyLockAssertion.assertionWithdrawInvariant.selector
        });

        // Try to withdraw with magic number - this should revert the assertion
        vm.prank(user1);
        vm.expectRevert("Caller withdraw amount higher than deposit");
        assertionAdopter.withdraw(69 ether);

        // Balance should stay the same due to revert
        assertEq(assertionAdopter.deposits(user1), 5 ether);
    }

    function testDelayedMagicNumberDrain() public {
        // Setup assertion for next transaction
        cl.assertion({
            adopter: address(assertionAdopter),
            createData: type(PhyLockAssertion).creationCode,
            fnSelector: PhyLockAssertion.assertionWithdrawInvariant.selector
        });

        // Fast forward 10 blocks to accumulate rewards
        vm.roll(block.number + 10);

        // Try to withdraw with magic number - this should revert the assertion
        vm.prank(user1);
        vm.expectRevert("Caller withdraw amount higher than deposit");
        assertionAdopter.withdraw(69 ether);

        // Balance should stay the same due to revert
        assertEq(assertionAdopter.deposits(user1), 5 ether);
    }

    function testMagicNumberDrainWith69Deposit() public {
        vm.prank(user1);
        assertionAdopter.deposit{value: 59 ether}();

        assertEq(assertionAdopter.totalDeposits(), 69 ether);

        // Register the assertion
        cl.assertion({
            adopter: address(assertionAdopter),
            createData: type(PhyLockAssertion).creationCode,
            fnSelector: PhyLockAssertion.assertionWithdrawInvariant.selector
        });

        // Try to withdraw with magic number - this should revert the assertion
        vm.prank(user1);
        vm.expectRevert("Caller withdraw amount higher than deposit");
        assertionAdopter.withdraw(69 ether);

        // Balance should stay the same due to revert
        assertEq(assertionAdopter.totalDeposits(), 69 ether);
    }

    function testMagicNumberDrainWith69UserDeposit() public {
        vm.prank(user1);
        assertionAdopter.deposit{value: 64 ether}();

        assertEq(assertionAdopter.deposits(user1), 69 ether);
        assertEq(assertionAdopter.totalDeposits(), 74 ether);

        // Register the assertion
        cl.assertion({
            adopter: address(assertionAdopter),
            createData: type(PhyLockAssertion).creationCode,
            fnSelector: PhyLockAssertion.assertionWithdrawInvariant.selector
        });

        // Try to withdraw with magic number - this is an edgecase because it's the magic number
        // Usually this should not revert because it matches the user's deposit.
        vm.prank(user1);
        vm.expectRevert("Caller withdraw amount mismatch");
        assertionAdopter.withdraw(69 ether);

        // Balance should stay the same due to revert
        assertEq(assertionAdopter.deposits(user1), 69 ether);
        assertEq(assertionAdopter.totalDeposits(), 74 ether);
    }

    function testMagicNumberDrainOver69UserDeposit() public {
        vm.prank(user1);
        assertionAdopter.deposit{value: 69 ether}();

        assertEq(assertionAdopter.deposits(user1), 74 ether);

        // Register the assertion
        cl.assertion({
            adopter: address(assertionAdopter),
            createData: type(PhyLockAssertion).creationCode,
            fnSelector: PhyLockAssertion.assertionWithdrawInvariant.selector
        });

        // Try to withdraw with magic number - this should revert the assertion
        vm.prank(user1);
        vm.expectRevert("Caller withdraw amount mismatch");
        assertionAdopter.withdraw(69 ether);

        // Balance should stay the same due to revert
        assertEq(assertionAdopter.totalDeposits(), 74 ether);
    }

    function testUserWithNoDepositWithdrawMagicNumber() public {
        assertEq(assertionAdopter.totalDeposits(), 10 ether);
        // Register the assertion
        cl.assertion({
            adopter: address(assertionAdopter),
            createData: type(PhyLockAssertion).creationCode,
            fnSelector: PhyLockAssertion.assertionWithdrawInvariant.selector
        });

        // Try to withdraw with magic number - this should revert the assertion
        // User 3 has no deposit
        vm.prank(user3);
        vm.expectRevert("Caller withdraw amount higher than deposit");
        assertionAdopter.withdraw(69 ether);

        // Balance should stay the same due to revert
        assertEq(assertionAdopter.totalDeposits(), 10 ether);
        assertEq(address(assertionAdopter).balance, 10 ether);
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
        cl.assertion({
            adopter: address(assertionAdopter),
            createData: type(PhyLockAssertion).creationCode,
            fnSelector: PhyLockAssertion.assertionWithdrawInvariant.selector
        });

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

    // Test that recreates a vulnerability in the assertion in:
    // https://github.com/phylaxsystems/credible-layer-starter/blob/de10c27e36a60cf6fbaf98b7fc670fb093cddee7/assertions/src/PhyLockAssertion.a.sol
    // Attack:
    // 10 eth deposited previously in the contract
    // Attacker deposits 10 ETH
    // deposit[Attacker]=10
    // Attacker crafts a transaction that calls:
    // 1x withdraw with amount= 10 ETH
    // 1x withdraw with amount=69 ETH
    // The assertion breaks because it counts the pre deposit of the attacker times the number of withdraw calls ->
    // 20 ETH (1x withdraw(10 ETH) + 1x withdraw(69 ETH) = 2 calls to withdraw)
    // IOW, it artificially inflates the expected payout to deposit[Attacker] X withdraw_calls
    // The attacker makes sure that the inflated expected payout is equal to the balance of the contract.
    // Then the actual withdraw calls empty the actual attacker's deposit.
    // Attacker calls withdraw N-1 times with  deposit[attacker] / ( withdraw_calls -1)
    // and one time with the special 69 ETH to drain the rest.
    function testBatchWithdrawals() public {
        BatchWithdrawals batchWithdrawals = new BatchWithdrawals(address(assertionAdopter));

        // Give the contract ETH and deposits
        vm.deal(address(batchWithdrawals), 100 ether);
        vm.prank(address(batchWithdrawals));
        assertionAdopter.deposit{value: 10 ether}();

        assertEq(assertionAdopter.deposits(address(batchWithdrawals)), 10 ether);
        assertEq(assertionAdopter.totalDeposits(), 20 ether);

        cl.assertion({
            adopter: address(assertionAdopter),
            createData: type(PhyLockAssertion).creationCode,
            fnSelector: PhyLockAssertion.assertionWithdrawInvariant.selector
        });

        // Now the transaction should reach the assertion and fail due to magic number
        vm.prank(user1);
        vm.expectRevert("Caller withdraw amount higher than deposit");
        batchWithdrawals.batchWithdraw();
    }

    function testBatchWithdrawals2() public {
        BatchWithdrawals batchWithdrawals = new BatchWithdrawals(address(assertionAdopter));

        vm.prank(user1);
        assertionAdopter.deposit{value: 40 ether}();

        // Give the contract ETH and deposits
        vm.deal(address(batchWithdrawals), 100 ether);
        vm.prank(address(batchWithdrawals));
        assertionAdopter.deposit{value: 10 ether}();

        assertEq(assertionAdopter.deposits(address(batchWithdrawals)), 10 ether);
        assertEq(assertionAdopter.totalDeposits(), 60 ether);

        cl.assertion({
            adopter: address(assertionAdopter),
            createData: type(PhyLockAssertion).creationCode,
            fnSelector: PhyLockAssertion.assertionWithdrawInvariant.selector
        });

        // Now the transaction should reach the assertion and fail due to magic number
        vm.prank(user1);
        vm.expectRevert("Caller withdraw amount mismatch");
        batchWithdrawals.batchWithdraw2();
    }
}

contract BatchWithdrawals {
    PhyLock public assertionAdopter;

    constructor(address assertionAdopter_) {
        assertionAdopter = PhyLock(assertionAdopter_);
    }

    receive() external payable {
        // Allow the contract to receive ETH
    }

    function batchWithdraw() public {
        assertionAdopter.withdraw(10 ether);
        assertionAdopter.withdraw(69 ether);
    }

    function batchWithdraw2() public {
        for (uint256 i = 0; i < 5; i++) {
            assertionAdopter.withdraw(2 ether);
        }
        assertionAdopter.withdraw(69 ether);
    }

    fallback() external {}
}
