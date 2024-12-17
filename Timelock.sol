// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IBEP20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract CreatorTimelock {
    IBEP20 public immutable token; // Token to be locked
    address public immutable creator; // Address that will receive the tokens
    uint256 public immutable releaseTime; // Timestamp for the release (after 10 years)
    uint256 public totalLocked; // Total amount of tokens locked
    bool public releaseClaimed; // Whether the release has been claimed

    // Events for improved transparency
    event TokensFunded(uint256 amount, address funder);
    event TokensReleased(uint256 amount, uint256 releaseStage);
    event EmergencyWithdrawal(address recipient, uint256 amount);

    constructor(
        IBEP20 _token,
        address _creator
    ) {
        token = _token;
        creator = _creator;

        // Set release time to 10 years from now
        releaseTime = block.timestamp + 10 * 365 days; // 10 years
    }

    // Fund the timelock contract with the locked amount (10% of total tokens for creators)
    function fund(uint256 totalSupply) external {
        require(totalLocked == 0, "Already funded");

        uint256 amountForCreators = totalSupply / 10; // 10% of the total supply
        require(
            token.transferFrom(msg.sender, address(this), amountForCreators),
            "Funding failed"
        );

        totalLocked = amountForCreators;
        
        emit TokensFunded(amountForCreators, msg.sender);
    }

    // Release tokens after the specified release time
    function release() external {
        require(msg.sender == creator, "Only creator can release tokens");
        require(block.timestamp >= releaseTime, "Cannot release tokens before the release time");
        require(!releaseClaimed, "Release already claimed");
        
        uint256 releaseAmount = totalLocked;
        releaseClaimed = true;

        require(token.transfer(creator, releaseAmount), "Release failed");
        
        emit TokensReleased(releaseAmount, 1);
    }

    // Emergency withdrawal function for contract owner (optional)
    function emergencyWithdraw() external {
        require(block.timestamp > releaseTime, "Cannot withdraw before release time");
        
        uint256 remainingBalance = token.balanceOf(address(this));
        require(remainingBalance > 0, "No tokens to withdraw");
        
        require(token.transfer(creator, remainingBalance), "Withdrawal failed");
        
        emit EmergencyWithdrawal(creator, remainingBalance);
    }

    // View function to check remaining locked tokens
    function getRemainingLockedTokens() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}
