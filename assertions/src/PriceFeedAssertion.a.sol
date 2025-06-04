// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {IPriceFeed} from "../../src/SimpleLending.sol";

contract PriceFeedAssertion is Assertion {
    IPriceFeed tokenPriceFeed;

    function triggers() external view override {
        registerCallTrigger(this.assertionPriceDeviation.selector, tokenPriceFeed.setPrice.selector);
    }

    function assertionPriceDeviation() external {
        tokenPriceFeed = IPriceFeed(ph.getAssertionAdopter());
        // price is in storage slot 1 of the tokenPriceFeed contract
        uint256[] memory stateChanges = getStateChangesUint(address(tokenPriceFeed), bytes32(uint256(1)));
        ph.forkPreState();
        // Get price before the transaction
        uint256 preTokenPrice = tokenPriceFeed.getPrice();
        ph.forkPostState();

        // Maximum allowed price deviation is 10% up or down
        uint256 maxPrice = (preTokenPrice * 110) / 100; // +10%
        uint256 minPrice = (preTokenPrice * 90) / 100; // -10%

        for (uint256 i = 0; i < stateChanges.length; i++) {
            uint256 price = stateChanges[i];
            if (price > maxPrice || price < minPrice) {
                revert("Price deviation exceeds 10% threshold");
            }
        }
    }
}
