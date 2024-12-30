# Secure Staking Contract

## Overview
A trustless and secure staking contract for BEP20/ERC20 tokens that offers multiple staking durations with different APY rates. The contract is designed with security-first principles, featuring comprehensive validations, no privileged roles, and protection against common smart contract vulnerabilities.

## Features

### Staking Options
- One Month: 10% APY
- Six Months: 20% APY
- Twelve Months: 30% APY

### Security Features
- Trustless design with no owner privileges
- Comprehensive input validation
- Transfer amount verification
- Stake structure validation
- Reentrancy protection
- Safe array operations
- Token transferability checks

### Technical Specifications
- Solidity Version: 0.8.26
- Dependencies:
  - OpenZeppelin ReentrancyGuard
  - OpenZeppelin SafeMath
  - OpenZeppelin IERC20

### Key Constants
```solidity
MAX_TOTAL_REWARDS = 250,000,000,000 tokens
MIN_STAKE_AMOUNT = 1 token
MAX_STAKE_AMOUNT = 1,000,000 tokens
```

## Contract Functions

### Core Functions

#### stake(uint256 amount, StakeDuration duration)
Creates a new stake with specified amount and duration.
```solidity
function stake(uint256 amount, StakeDuration duration) external nonReentrant
```
- Validates stake parameters
- Verifies token transfer
- Updates state
- Emits StakeCreated event

#### unstake(uint256 _stakeIndex)
Withdraws staked tokens plus rewards.
```solidity
function unstake(uint256 _stakeIndex) external nonReentrant
```
- Validates stake exists
- Calculates rewards
- Updates state
- Transfers tokens
- Emits Unstaked event

### View Functions

#### getUserStakes(address user)
Returns all stakes for a given user.
```solidity
function getUserStakes(address user) external view returns (Stake[] memory)
```

#### getPendingRewards(address user, uint256 stakeIndex)
Calculates pending rewards for a specific stake.
```solidity
function getPendingRewards(address user, uint256 stakeIndex) external view returns (uint256)
```

#### getStakingPeriod(StakeDuration duration)
Returns staking period details for a given duration.
```solidity
function getStakingPeriod(StakeDuration duration) external view returns (StakingPeriod memory)
```

## Events

```solidity
event StakeCreated(address indexed user, uint256 amount, StakeDuration duration, uint256 apy)
event Unstaked(address indexed user, uint256 totalAmount, uint256 rewards)
event TransferFailed(address indexed user, uint256 amount, string reason)
```

## Security Measures

### Token Transfer Safety
- Pre-deployment token transferability check
- Balance verification before and after transfers
- Transfer success verification
- Clear error handling

### Stake Validation
- Amount boundaries (min/max)
- Duration validation
- APY range checks
- Timestamp validation
- Full stake structure validation

### Array Safety
- Length validation
- Index bounds checking
- Safe array manipulation
- Proper element removal

### State Management
- Follows Check-Effects-Interactions pattern
- ReentrancyGuard implementation
- State updates before transfers
- Balance tracking

## Usage Guide

### Deployment
1. Deploy contract with token address
2. Token transferability will be checked during deployment
3. Staking periods are automatically initialized

### For Users

#### To Stake Tokens:
1. Approve contract to spend tokens
```javascript
await token.approve(stakingContract.address, amount);
```

2. Call stake function
```javascript
await stakingContract.stake(amount, StakeDuration.OneMonth);
```

#### To Unstake Tokens:
1. Get stake index from getUserStakes
2. Call unstake function
```javascript
await stakingContract.unstake(stakeIndex);
```

#### To Check Rewards:
```javascript
const rewards = await stakingContract.getPendingRewards(userAddress, stakeIndex);
```

### Error Handling
The contract provides clear error messages for all possible failure scenarios:
- Insufficient balance
- Invalid stake parameters
- Transfer failures
- Invalid operations

## Security Considerations
- No privileged roles or admin functions
- No emergency withdrawal mechanisms
- No ability to modify staking parameters after deployment
- All operations are permissionless and trustless

## Testing
Recommended test scenarios:
1. Stake creation with various amounts and durations
2. Reward calculations
3. Unstaking process
4. Array manipulation safety
5. Transfer failure scenarios
6. Boundary conditions
7. State consistency

## Limitations
- Fixed APY rates
- Fixed staking durations
- No stake modification after creation
- No partial withdrawals

## License
MIT License

## Audit Status
The contract has been designed with security best practices and has addressed common vulnerabilities. However, it is recommended to undergo a professional audit before mainnet deployment.
