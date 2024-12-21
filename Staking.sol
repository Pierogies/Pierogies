// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Staking contract with multiple duration options and security measures
contract Staking is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    IERC20 public token;
    uint256 public constant MAX_TOTAL_REWARDS = 250_000_000_000 * 10**18;
    uint256 public constant OWNERSHIP_TRANSFER_TIMELOCK = 7 days;
    uint256 public constant MIN_STAKE_AMOUNT = 1 * 10**18;
    uint256 public constant MAX_STAKE_AMOUNT = 1_000_000 * 10**18;

    uint256 private constant ONE_MONTH_APY = 10;
    uint256 private constant SIX_MONTHS_APY = 20;
    uint256 private constant TWELVE_MONTHS_APY = 30;

    uint256 public totalRewardsPaid;
    uint256 public totalLockedTokens;
    uint256 public ownershipTransferTimestamp;
    address public pendingOwner;
    bool public emergencyMode;

    enum StakeDuration {
        OneMonth,
        SixMonths,
        TwelveMonths
    }

    struct Stake {
        uint256 amount;
        uint256 timestamp;
        uint256 apy;
        StakeDuration duration;
    }

    struct StakingPeriod {
        uint256 duration;
        uint256 apy;
    }

    mapping(address => Stake[]) public stakes;
    mapping(StakeDuration => StakingPeriod) public stakingPeriods;

    // Events
    event StakeCreated(address indexed user, uint256 amount, StakeDuration duration, uint256 apy);
    event EmergencyModeEnabled(address indexed by);
    event EmergencyModeDisabled(address indexed by);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event TokensRecovered(address indexed tokenAddress, address indexed recipient, uint256 amount);
    event Unstaked(address indexed user, uint256 totalAmount, uint256 rewards);

    constructor(address _tokenAddress) Ownable(msg.sender) {
        require(_tokenAddress != address(0), "Invalid token address");
        token = IERC20(_tokenAddress);

        stakingPeriods[StakeDuration.OneMonth] = StakingPeriod({
            duration: 30 days,
            apy: ONE_MONTH_APY
        });
        stakingPeriods[StakeDuration.SixMonths] = StakingPeriod({
            duration: 180 days,
            apy: SIX_MONTHS_APY
        });
        stakingPeriods[StakeDuration.TwelveMonths] = StakingPeriod({
            duration: 360 days,
            apy: TWELVE_MONTHS_APY
        });
    }

    modifier whenEmergency() {
        require(emergencyMode, "Not in emergency mode");
        _;
    }

    modifier whenNotEmergency() {
        require(!emergencyMode, "In emergency mode");
        _;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function validateStake(
        uint256 amount,
        StakeDuration duration
    ) internal view returns (uint256 apy) {
        require(amount >= MIN_STAKE_AMOUNT, "Stake amount too low");
        require(amount <= MAX_STAKE_AMOUNT, "Stake amount too high");
        
        StakingPeriod memory period = stakingPeriods[duration];
        require(period.duration > 0, "Invalid staking duration");
        
        return period.apy;
    }

    function stake(uint256 amount, StakeDuration duration) 
        external 
        nonReentrant 
        whenNotEmergency 
    {
        uint256 apy = validateStake(amount, duration);
        
        require(
            token.balanceOf(msg.sender) >= amount,
            "Insufficient token balance"
        );
        
        uint256 currentAllowance = token.allowance(msg.sender, address(this));
        require(
            currentAllowance >= amount,
            string(abi.encodePacked(
                "Insufficient token allowance. Current allowance: ",
                toString(currentAllowance),
                ", Required amount: ",
                toString(amount)
            ))
        );

        require(
            token.transferFrom(msg.sender, address(this), amount), 
            "Token transfer failed"
        );

        totalLockedTokens = totalLockedTokens.add(amount);

        Stake memory newStake = Stake({
            amount: amount,
            timestamp: block.timestamp,
            apy: apy,
            duration: duration
        });

        require(
            newStake.amount > 0 &&
            newStake.timestamp <= block.timestamp &&
            newStake.apy <= TWELVE_MONTHS_APY &&
            uint256(newStake.duration) <= uint256(StakeDuration.TwelveMonths),
            "Invalid stake data"
        );

        stakes[msg.sender].push(newStake);

        emit StakeCreated(msg.sender, amount, duration, apy);
    }

    function calculateRewards(Stake memory _stake) internal view returns (uint256) {
        require(_stake.amount > 0, "Invalid stake amount");
        require(_stake.timestamp <= block.timestamp, "Invalid stake timestamp");
        require(_stake.apy <= TWELVE_MONTHS_APY, "Invalid APY");

        StakingPeriod memory period = stakingPeriods[_stake.duration];
        require(period.duration > 0, "Invalid staking period");

        uint256 stakingTime = block.timestamp.sub(_stake.timestamp);
        require(stakingTime >= period.duration, "Minimum staking period not reached");

        uint256 stakingPeriod = stakingTime / 30 days;
        require(stakingPeriod <= 365, "Staking period too long");
        
        uint256 rewards = _stake.amount.mul(_stake.apy).mul(stakingPeriod).div(100);
        require(rewards <= MAX_TOTAL_REWARDS.sub(totalRewardsPaid), "Reward calculation overflow");
        
        return rewards;
    }

    function unstake(uint256 _stakeIndex) 
        external 
        nonReentrant 
        whenNotEmergency 
    {
        require(_stakeIndex < stakes[msg.sender].length, "Invalid stake index");
        
        Stake storage userStake = stakes[msg.sender][_stakeIndex];
        uint256 rewards = calculateRewards(userStake);
        
        require(
            totalRewardsPaid.add(rewards) <= MAX_TOTAL_REWARDS, 
            "Rewards exceed maximum allocation"
        );

        uint256 totalAmount = userStake.amount.add(rewards);
        totalRewardsPaid = totalRewardsPaid.add(rewards);
        totalLockedTokens = totalLockedTokens.sub(userStake.amount);
        
        address recipient = msg.sender;
        stakes[msg.sender][_stakeIndex] = stakes[msg.sender][stakes[msg.sender].length - 1];
        stakes[msg.sender].pop();

        require(
            token.balanceOf(address(this)) >= totalAmount,
            "Insufficient contract balance"
        );
        
        require(
            token.transfer(recipient, totalAmount) &&
            token.balanceOf(recipient) >= totalAmount,
            "Token transfer failed"
        );

        emit Unstaked(recipient, totalAmount, rewards);
    }

    function enableEmergencyMode() external onlyOwner {
        require(!emergencyMode, "Emergency mode already enabled");
        emergencyMode = true;
        emit EmergencyModeEnabled(msg.sender);
    }

    function disableEmergencyMode() external onlyOwner {
        require(emergencyMode, "Emergency mode not enabled");
        emergencyMode = false;
        emit EmergencyModeDisabled(msg.sender);
    }

    function emergencyWithdraw(uint256 _stakeIndex) 
        external 
        nonReentrant 
        whenEmergency 
    {
        require(_stakeIndex < stakes[msg.sender].length, "Invalid stake index");
        
        Stake storage userStake = stakes[msg.sender][_stakeIndex];
        uint256 amount = userStake.amount;
        
        totalLockedTokens = totalLockedTokens.sub(amount);
        
        stakes[msg.sender][_stakeIndex] = stakes[msg.sender][stakes[msg.sender].length - 1];
        stakes[msg.sender].pop();

        require(
            token.balanceOf(address(this)) >= amount,
            "Insufficient contract balance"
        );
        
        require(
            token.transfer(msg.sender, amount) &&
            token.balanceOf(msg.sender) >= amount,
            "Token transfer failed"
        );

        emit EmergencyWithdraw(msg.sender, amount);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) 
        external 
        onlyOwner 
        nonReentrant 
    {
        require(tokenAddress != address(token), "Cannot withdraw staking token");
        
        IERC20 recoveryToken = IERC20(tokenAddress);
        
        uint256 contractBalance = recoveryToken.balanceOf(address(this));
        require(contractBalance >= tokenAmount, "Insufficient balance to recover");
        
        if (tokenAddress == address(token)) {
            uint256 availableToRecover = contractBalance.sub(totalLockedTokens);
            require(
                tokenAmount <= availableToRecover,
                "Cannot withdraw staked tokens"
            );
        }
        
        address recipient = owner();
        
        require(
            recoveryToken.transfer(recipient, tokenAmount) &&
            recoveryToken.balanceOf(recipient) >= tokenAmount,
            "Token recovery failed"
        );
        
        emit TokensRecovered(tokenAddress, recipient, tokenAmount);
    }

    function initiateOwnershipTransfer(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        pendingOwner = newOwner;
        ownershipTransferTimestamp = block.timestamp + OWNERSHIP_TRANSFER_TIMELOCK;
    }

    function completeOwnershipTransfer() external {
        require(msg.sender == pendingOwner, "Only pending owner can complete transfer");
        require(block.timestamp >= ownershipTransferTimestamp, "Timelock not expired");
        _transferOwnership(pendingOwner);
        pendingOwner = address(0);
    }

    function renounceOwnershipPermanently() external onlyOwner {
        _transferOwnership(address(0));
    }

    function getRecoverableAmount(address tokenAddress) external view returns (uint256) {
        if (tokenAddress == address(token)) {
            uint256 contractBalance = IERC20(tokenAddress).balanceOf(address(this));
            if (contractBalance <= totalLockedTokens) {
                return 0;
            }
            return contractBalance.sub(totalLockedTokens);
        } else {
            return IERC20(tokenAddress).balanceOf(address(this));
        }
    }

    function getUserStakes(address user) external view returns (Stake[] memory) {
        return stakes[user];
    }

    function getPendingRewards(address user, uint256 stakeIndex) external view returns (uint256) {
        require(stakeIndex < stakes[user].length, "Invalid stake index");
        return calculateRewards(stakes[user][stakeIndex]);
    }
}
