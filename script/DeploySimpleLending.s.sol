// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/SimpleLending.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @title MockToken
/// @notice A simple ERC20 token for testing the lending protocol
contract MockToken is ERC20 {
    constructor() ERC20("Mock Token", "MTK") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    /// @notice Allows anyone to mint tokens for testing purposes
    /// @param to The address to mint tokens to
    /// @param amount The amount of tokens to mint
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract DeployScript is Script {
    function run() public {
        // Load private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy mock token
        MockToken mockToken = new MockToken();
        console.log("MockToken deployed at:", address(mockToken));

        // Deploy price feeds
        MockPriceFeed ethPriceFeed = new MockPriceFeed();
        MockTokenPriceFeed tokenPriceFeed = new MockTokenPriceFeed();
        console.log("ETH Price Feed deployed at:", address(ethPriceFeed));
        console.log("Token Price Feed deployed at:", address(tokenPriceFeed));

        // Set initial prices (in USD with 18 decimals)
        ethPriceFeed.setPrice(2000 ether); // $2000 per ETH
        tokenPriceFeed.setPrice(1 ether); // $1 per token

        // Deploy SimpleLending contract
        SimpleLending lending = new SimpleLending(address(mockToken), address(ethPriceFeed), address(tokenPriceFeed));
        console.log("SimpleLending deployed at:", address(lending));

        vm.stopBroadcast();
    }
}
