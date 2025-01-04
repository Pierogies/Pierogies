// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Staking is ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 public immutable token;
    uint256 public constant MAX_TOTAL_REWARDS = 250_000_000_000 * 10**18;
    uint256 public constant MIN_STAKE_AMOUNT = 1 * 10**18;
    uint256 public constant MAX_STAKE_AMOUNT = 1_000_000 * 10**18;

    uint256 private constant ONE_MONTH_APY = 10;
    uint256 private constant SIX_MONTHS_APY = 20;
    uint256 private constant TWELVE_MONTHS_APY = 30;

    uint256 public totalRewardsPaid;
    uint256 public totalLockedTokens;

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

    event StakeCreated(address indexed user, uint256 amount, StakeDuration duration, uint256 apy);
    event Unstaked(address indexed user, uint256 totalAmount, uint256 rewards);
    event TransferFailed(address indexed user, uint256 amount, string reason);

    constructor(address _tokenAddress) {
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

    function validateStakeStruct(Stake memory _stake) internal view returns (bool) {
        require(_stake.amount > 0, "Stake amount must be greater than 0");
        require(_stake.timestamp <= block.timestamp, "Invalid stake timestamp");
        require(_stake.apy <= TWELVE_MONTHS_APY, "APY exceeds maximum allowed");
        require(
            uint256(_stake.duration) <= uint256(StakeDuration.TwelveMonths),
            "Invalid staking duration"
        );
        return true;
    }

    function validateStake(uint256 amount, StakeDuration duration) 
        internal 
        view 
        returns (uint256 apy) 
    {
        require(amount >= MIN_STAKE_AMOUNT, "Stake amount too low");
        require(amount <= MAX_STAKE_AMOUNT, "Stake amount too high");
        
        StakingPeriod memory period = stakingPeriods[duration];
        require(period.duration > 0, "Invalid staking duration");
        
        return period.apy;
    }

    function stake(uint256 amount, StakeDuration duration) external nonReentrant {
        uint256 apy = validateStake(amount, duration);
        
        require(token.balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(token.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
        
        uint256 preBalance = token.balanceOf(address(this));
        
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        require(
            token.balanceOf(address(this)) == preBalance.add(amount),
            "Transfer amount mismatch"
        );
        
        Stake memory newStake = Stake({
            amount: amount,
            timestamp: block.timestamp,
            apy: apy,
            duration: duration
        });

        require(validateStakeStruct(newStake), "Invalid stake structure");
        
        totalLockedTokens = totalLockedTokens.add(amount);
        stakes[msg.sender].push(newStake);
        
        emit StakeCreated(msg.sender, amount, duration, apy);
    }

    function calculateRewards(Stake memory _stake) public view returns (uint256) {
        require(_stake.amount > 0, "Invalid stake amount");
        require(_stake.timestamp <= block.timestamp, "Invalid stake timestamp");
        require(_stake.apy <= TWELVE_MONTHS_APY, "Invalid APY");

        StakingPeriod memory period = stakingPeriods[_stake.duration];
        require(period.duration > 0, "Invalid staking period");

        uint256 stakingTime = block.timestamp.sub(_stake.timestamp);
        require(stakingTime >= period.duration, "Minimum staking period not reached");

        uint256 stakingPeriod = stakingTime.div(30 days);
        require(stakingPeriod <= 365, "Staking period too long");
        
        uint256 rewards = _stake.amount.mul(_stake.apy).mul(stakingPeriod).div(100);
        require(
            rewards <= MAX_TOTAL_REWARDS.sub(totalRewardsPaid),
            "Reward calculation overflow"
        );
        
        return rewards;
    }

    function unstake(uint256 _stakeIndex) external nonReentrant {
        uint256 userStakesLength = stakes[msg.sender].length;
        require(userStakesLength > 0, "No stakes found");
        require(_stakeIndex < userStakesLength, "Invalid stake index");
        
        Stake storage userStake = stakes[msg.sender][_stakeIndex];
        require(validateStakeStruct(userStake), "Invalid stake data");
        
        uint256 rewards = calculateRewards(userStake);
        uint256 totalAmount = userStake.amount.add(rewards);
        
        require(
            totalRewardsPaid.add(rewards) <= MAX_TOTAL_REWARDS,
            "Rewards exceed maximum allocation"
        );
        
        uint256 preBalance = token.balanceOf(msg.sender);
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= totalAmount, "Insufficient contract balance");
        
        // Update state before transfer
        totalRewardsPaid = totalRewardsPaid.add(rewards);
        totalLockedTokens = totalLockedTokens.sub(userStake.amount);
        
        // Safe array manipulation
        if (_stakeIndex != userStakesLength - 1) {
            stakes[msg.sender][_stakeIndex] = stakes[msg.sender][userStakesLength - 1];
        }
        stakes[msg.sender].pop();
        
        // Perform transfer after state updates
        bool success = token.transfer(msg.sender, totalAmount);
        if (!success) {
            emit TransferFailed(msg.sender, totalAmount, "Transfer failed");
            revert("Transfer failed");
        }
        
        require(
            token.balanceOf(msg.sender) == preBalance.add(totalAmount),
            "Transfer amount verification failed"
        );
        
        emit Unstaked(msg.sender, totalAmount, rewards);
    }

    function getUserStakes(address user) external view returns (Stake[] memory) {
        return stakes[user];
    }

    function getPendingRewards(address user, uint256 stakeIndex) external view returns (uint256) {
        require(stakeIndex < stakes[user].length, "Invalid stake index");
        return calculateRewards(stakes[user][stakeIndex]);
    }

    function getStakingPeriod(StakeDuration duration) external view returns (StakingPeriod memory) {
        return stakingPeriods[duration];
    }
}
