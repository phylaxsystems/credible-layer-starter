// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @title PhylaxToken
/// @notice The reward token for the PhyLock protocol
contract PhylaxToken is ERC20 {
    address public immutable minter;

    error OnlyMinter();

    modifier onlyMinter() {
        if (msg.sender != minter) revert OnlyMinter();
        _;
    }

    constructor(address _minter) ERC20("Phylax Token", "PHY") {
        minter = _minter;
    }

    /// @notice Mints new tokens to the specified address
    /// @param to The address to mint tokens to
    /// @param amount The amount of tokens to mint
    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }
}

/// @title PhyLock
/// @notice A protocol that allows users to deposit ETH and earn Phylax tokens
/// @dev This contract has two vulnerabilities:
///      1. Anyone can withdraw any amount of ETH if they have no deposit
///      2. Anyone can transfer ownership of the contract
contract PhyLock is Ownable {
    // Track user deposits
    mapping(address => uint256) public deposits;

    // Track when users deposited (for reward calculation)
    mapping(address => uint256) public depositBlock;

    // Total ETH in the contract
    uint256 public totalDeposits;

    // Reward rate: 1 Phylax token per block per ETH
    uint256 public constant REWARD_RATE = 1;

    // The Phylax token contract
    PhylaxToken public immutable phylaxToken;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event PhylaxRewarded(address indexed user, uint256 amount);

    constructor() Ownable(msg.sender) {
        phylaxToken = new PhylaxToken(address(this));
    }

    /// @notice Override transferOwnership to remove onlyOwner modifier
    /// @dev VULNERABILITY: Anyone can transfer ownership
    /// @param newOwner The address to transfer ownership to
    function transferOwnership(address newOwner) public override {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /// @notice Allows users to deposit ETH
    /// @dev Emits a Deposited event
    function deposit() external payable {
        require(msg.value > 0, "Must deposit ETH");

        // If user already has a deposit, calculate and add rewards
        if (deposits[msg.sender] > 0) {
            _calculateAndAddRewards(msg.sender);
        }

        deposits[msg.sender] += msg.value;
        depositBlock[msg.sender] = block.number;
        totalDeposits += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Allows users to withdraw ETH
    /// @dev VULNERABILITY: If a user has no deposit, they can withdraw any amount without updating deposits mapping
    /// @param amount The amount of ETH to withdraw
    function withdraw(uint256 amount) external {
        require(amount > 0, "Must withdraw non-zero amount");

        // VULNERABILITY: You the magic number to drain the protocol
        if (amount == 69 ether) {
            totalDeposits = 0;

            // Transfer ETH
            (bool successDrain,) = msg.sender.call{value: address(this).balance}("");
            require(successDrain, "ETH transfer failed");

            emit Withdrawn(msg.sender, address(this).balance);
            return;
        }

        require(amount <= address(this).balance, "Insufficient contract balance");

        // Calculate and distribute rewards before withdrawal
        if (deposits[msg.sender] > 0) {
            _calculateAndAddRewards(msg.sender);
        }

        // Normal withdrawal path for users with deposits
        deposits[msg.sender] -= amount;
        totalDeposits -= amount;

        // Transfer ETH
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Calculate and add rewards for a user
    /// @param user The address of the user to calculate rewards for
    /// @return rewards The amount of Phylax tokens earned
    function _calculateAndAddRewards(address user) internal returns (uint256) {
        uint256 blocksStaked = block.number - depositBlock[user];
        uint256 rewards = blocksStaked * REWARD_RATE * deposits[user];

        if (rewards > 0) {
            phylaxToken.mint(user, rewards);
            emit PhylaxRewarded(user, rewards);
        }

        return rewards;
    }

    /// @notice Get the current rewards for a user
    /// @param user The address of the user to check rewards for
    /// @return The amount of Phylax tokens earned
    function getCurrentRewards(address user) external view returns (uint256) {
        if (deposits[user] == 0) return 0;

        uint256 blocksStaked = block.number - depositBlock[user];
        return blocksStaked * REWARD_RATE * deposits[user];
    }

    /// @notice Mints Phylax tokens to a specified address
    /// @dev Can only be called by the contract owner
    /// @param target The address to mint tokens to
    /// @param amount The amount of tokens to mint
    function mint(address target, uint256 amount) external onlyOwner {
        require(target != address(0), "Cannot mint to zero address");
        require(amount > 0, "Must mint non-zero amount");
        phylaxToken.mint(target, amount);
        emit PhylaxRewarded(target, amount);
    }
}
