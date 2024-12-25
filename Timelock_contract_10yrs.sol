// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IBEP20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Timelock {
    IBEP20 public immutable token; // Token to be locked
    address public immutable beneficiary; // Address that will receive the tokens
    uint256 public immutable releaseTime; // Timestamp for token release
    uint256 public totalLocked; // Total amount of tokens locked
    bool public tokensReleased; // Whether the tokens have been released

    // Events for improved transparency
    event TokensFunded(uint256 amount, address funder);
    event TokensReleased(uint256 amount);
    event EmergencyWithdrawal(address recipient, uint256 amount);

    constructor(
        IBEP20 _token,
        address _beneficiary
    ) {
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = block.timestamp + 10 years; // Lock for 10 years from deployment
    }

    // Fund the timelock contract with the locked amount
    function fund(uint256 amount) external {
        require(totalLocked == 0, "Already funded");
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Funding failed"
        );
        totalLocked = amount;
        
        emit TokensFunded(amount, msg.sender);
    }

    // Release tokens after 10 years
    function release() external {
        require(msg.sender == beneficiary, "Only beneficiary can release tokens");
        require(block.timestamp >= releaseTime, "Tokens are still locked");
        require(!tokensReleased, "Tokens already released");
        
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "No tokens to release");
        
        tokensReleased = true;
        require(token.transfer(beneficiary, amount), "Release failed");
        
        emit TokensReleased(amount);
    }

    // Emergency withdrawal function for contract owner
    function emergencyWithdraw() external {
        require(
            block.timestamp > releaseTime && !tokensReleased,
            "Cannot withdraw before release time or after release"
        );
        
        uint256 remainingBalance = token.balanceOf(address(this));
        require(remainingBalance > 0, "No tokens to withdraw");
        
        require(token.transfer(beneficiary, remainingBalance), "Withdrawal failed");
        
        emit EmergencyWithdrawal(beneficiary, remainingBalance);
    }

    // View function to check remaining locked tokens
    function getRemainingLockedTokens() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}
