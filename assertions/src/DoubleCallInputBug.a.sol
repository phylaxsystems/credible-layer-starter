// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

contract DoubleCallInputBug is Assertion {
    ISupplier public supplier;

    constructor(ISupplier _supplier) {
        supplier = _supplier;
    }

    /**
     * @notice Required implementation of triggers function
     */
    function triggers() external view override {
        // Register triggers for the assertion function
        registerCallTrigger(this.assertSingleSupplyCall.selector, ISupplier.supply.selector);
    }

    /**
     * @notice Minimal assertion that demonstrates the double-call issue
     * @dev This should detect exactly 1 borrow call, but PhEvm reports 2
     */
    function assertSingleSupplyCall() external {
        // Get all borrow calls to the pool using the exact L2Pool.borrow(bytes32) signature
        // This should only catch the external L2Pool.borrow(bytes32) calls, not the internal Pool.borrow() calls
        PhEvm.CallInputs[] memory supplyCalls = ph.getCallInputs(address(supplier), ISupplier.supply.selector);

        // This should be 1, but PhEvm reports 2
        require(supplyCalls.length == 1, "Expected exactly 1 L2Pool.supply(uint256) call, got 2");
    }
}

contract Supplier {
    mapping(address => uint256) public balances;
    uint256 public totalSupply;

    function supply(uint256 amount) external {
        supply(amount, 0);
    }

    function supply(uint256 amount, uint256 amount2) public {
        balances[msg.sender] += amount;
        totalSupply += amount;
        balances[msg.sender] += amount2;
        totalSupply += amount2;
    }
}

interface ISupplier {
    function supply(uint256 amount) external;
}
