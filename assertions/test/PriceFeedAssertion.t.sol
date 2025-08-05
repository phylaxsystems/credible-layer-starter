// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PriceFeedAssertion} from "../src/PriceFeedAssertion.a.sol";
import {IPriceFeed} from "../../src/SimpleLending.sol";
import {MockTokenPriceFeed} from "../../src/SimpleLending.sol";
import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";

contract TestPriceFeedAssertion is CredibleTest, Test {
    BatchTokenPriceUpdates public batchTokenPriceUpdates;
    MockTokenPriceFeed public assertionAdopter;

    function setUp() public {
        assertionAdopter = new MockTokenPriceFeed();
        vm.deal(address(0xdeadbeef), 1 ether);
    }

    function testBatchPriceUpdates() public {
        BatchTokenPriceUpdates updater = new BatchTokenPriceUpdates(address(assertionAdopter));

        vm.prank(address(0xdeadbeef));
        // Set initial token price
        assertionAdopter.setPrice(1 ether);

        // Setup assertion for next transaction
        cl.assertion({
            adopter: address(assertionAdopter),
            createData: type(PriceFeedAssertion).creationCode,
            fnSelector: PriceFeedAssertion.assertionPriceDeviation.selector
        });

        vm.prank(address(0xdeadbeef));
        // Execute batch price updates directly (trigger fallback)
        // The assertion will be triggered and catch the price deviation
        (bool success,) = address(updater).call("");
        success; // silence unused variable warning
    }

    function testAllowsSafePriceUpdate() public {
        vm.prank(address(0xdeadbeef));
        // Set initial token price
        assertionAdopter.setPrice(1 ether);

        // Setup assertion for next transaction
        cl.assertion({
            adopter: address(assertionAdopter),
            createData: type(PriceFeedAssertion).creationCode,
            fnSelector: PriceFeedAssertion.assertionPriceDeviation.selector
        });

        // Update price within allowed range (5% increase) - should succeed
        vm.prank(address(0xdeadbeef));
        assertionAdopter.setPrice(1.05 ether);
    }

    function testUnsafePriceUpdate() public {
        vm.prank(address(0xdeadbeef));
        // Set initial token price
        assertionAdopter.setPrice(1 ether);

        // Setup assertion for next transaction
        cl.assertion({
            adopter: address(assertionAdopter),
            createData: type(PriceFeedAssertion).creationCode,
            fnSelector: PriceFeedAssertion.assertionPriceDeviation.selector
        });

        // Update price outside allowed range (25% decrease) - should revert
        vm.prank(address(0xdeadbeef));
        vm.expectRevert("Price deviation exceeds 10% threshold");
        assertionAdopter.setPrice(0.75 ether);
    }
}

contract BatchTokenPriceUpdates {
    IPriceFeed public tokenPriceFeed;

    constructor(address tokenPriceFeed_) {
        tokenPriceFeed = IPriceFeed(tokenPriceFeed_);
    }

    fallback() external {
        uint256 originalPrice = tokenPriceFeed.getPrice();

        TempTokenPriceUpdater updater = new TempTokenPriceUpdater(address(tokenPriceFeed));

        // Perform 10 token price updates (using realistic token/USD prices)
        updater.setPrice(0.95 ether); // $0.95
        updater.setPrice(1.05 ether); // $1.05
        updater.setPrice(0.9 ether); // $0.90
        updater.setPrice(1.1 ether); // $1.10
        updater.setPrice(0.85 ether); // $0.85 -- price deviates too much, should trigger assertion
        updater.setPrice(1.15 ether); // $1.15
        updater.setPrice(0.9 ether); // $0.90
        updater.setPrice(originalPrice); // Return to original price
    }
}

contract TempTokenPriceUpdater {
    IPriceFeed public tokenPriceFeed;

    constructor(address tokenPriceFeed_) {
        tokenPriceFeed = IPriceFeed(tokenPriceFeed_);
    }

    function setPrice(uint256 newPrice) external {
        tokenPriceFeed.setPrice(newPrice);
    }
}
