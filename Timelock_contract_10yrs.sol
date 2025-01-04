
// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IBEP20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract CreatorTimelock {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    IBEP20 public immutable token;
    address public immutable creator;
    uint256 public immutable releaseTime;
    uint256 public totalLocked;
    bool public releaseClaimed;

    event TokensFunded(uint256 amount, address funder);
    event TokensReleased(uint256 amount, uint256 releaseStage);
    event TransferFailed(address intended_recipient, uint256 amount);

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    constructor(IBEP20 _token, address _creator) {
        require(address(_token) != address(0), "Invalid token address");
        require(_creator != address(0), "Invalid creator address");
        
        token = _token;
        creator = _creator;
        releaseTime = block.timestamp + 10 * 365 days;
        _status = _NOT_ENTERED;
    }

    function fund(uint256 totalSupply) external nonReentrant {
        require(totalLocked == 0, "Already funded");
        require(totalSupply > 0, "Invalid total supply");
        
        uint256 amountForCreators = totalSupply / 10;
        
        require(
            token.allowance(msg.sender, address(this)) >= amountForCreators,
            "Insufficient allowance"
        );
        
        uint256 preBalance = token.balanceOf(address(this));
        
        require(
            token.transferFrom(msg.sender, address(this), amountForCreators),
            "Funding failed"
        );
        
        require(
            token.balanceOf(address(this)) == preBalance + amountForCreators,
            "Transfer amount mismatch"
        );
        
        totalLocked = amountForCreators;
        emit TokensFunded(amountForCreators, msg.sender);
    }

    function release() external nonReentrant {
        require(msg.sender == creator, "Only creator can release tokens");
        require(block.timestamp >= releaseTime, "Cannot release tokens before the release time");
        require(!releaseClaimed, "Release already claimed");
        
        uint256 releaseAmount = totalLocked;
        uint256 preBalance = token.balanceOf(creator);
        
        releaseClaimed = true;
        
        bool success = token.transfer(creator, releaseAmount);
        if (!success) {
            releaseClaimed = false;
            emit TransferFailed(creator, releaseAmount);
            revert("Release failed");
        }
        
        require(
            token.balanceOf(creator) == preBalance + releaseAmount,
            "Transfer amount mismatch"
        );
        
        emit TokensReleased(releaseAmount, 1);
    }

    function getRemainingLockedTokens() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}
