# 🥟 Pierogies Staking Contract

## Overview
Secure and flexible staking contract for Pierogies (PIRGS) token with multiple staking durations and APY rates. Features comprehensive security measures and emergency withdrawal system.

## Features

### Staking Options
- 1 Month: 10% APY
- 6 Months: 20% APY
- 12 Months: 30% APY

### Limits
- Minimum stake: 1 PIRGS
- Maximum stake: 1,000,000 PIRGS
- Maximum total rewards: 250B PIRGS

### Security Features
- Reentrancy protection
- Two-step ownership transfer with 7-day timelock
- Emergency mode with secure withdrawal process
- Protected staked tokens recovery system
- Comprehensive stake validation
- Time-based restrictions

## Functions

### User Functions
- `stake(uint256 amount, StakeDuration duration)`: Stake tokens
- `unstake(uint256 stakeIndex)`: Unstake tokens and claim rewards
- `emergencyWithdraw(uint256 stakeIndex)`: Withdraw stake without rewards (emergency mode only)
- `getUserStakes(address user)`: View all stakes for a user
- `getPendingRewards(address user, uint256 stakeIndex)`: Check pending rewards

### Admin Functions
- `enableEmergencyMode()`: Enable emergency mode
- `disableEmergencyMode()`: Disable emergency mode
- `recoverERC20()`: Recover accidentally sent tokens
- `initiateOwnershipTransfer()`: Start ownership transfer
- `completeOwnershipTransfer()`: Complete ownership transfer
- `renounceOwnershipPermanently()`: Permanently renounce ownership

## Technical Stack
- Solidity: 0.8.26
- Framework: OpenZeppelin 5.0.0
- Network: BNB Chain

## Security Measures

### Access Control
- Role-based access control
- Timelock for ownership changes
- Emergency mode restrictions

### Token Safety
- Locked tokens tracking
- Strict allowance checks
- Balance validations
- Protected staked tokens

### Data Validation
- Stake structure validation
- Duration checks
- Amount limits
- APY restrictions

## Error Messages
The contract provides clear error messages for all operations, including:
- Insufficient balances
- Invalid stake parameters
- Duration restrictions
- Emergency mode status
- Transfer failures
- Access control violations

## Events
All important operations emit events for off-chain tracking:
- StakeCreated
- Unstaked
- EmergencyModeEnabled
- EmergencyModeDisabled
- EmergencyWithdraw
- TokensRecovered

## Deployment
1. Deploy PIRGS token contract
2. Deploy staking contract with PIRGS token address
3. Transfer ownership to timelock contract (optional)
4. Verify contracts on block explorer

## Testing
- Comprehensive test suite available
- Coverage includes all functions and edge cases
- Emergency scenarios tested
- Ownership transfer verified
- Reward calculations validated

## Audited
The contract has been audited and all found issues have been fixed, including:
- Access control improvements
- Token transfer validations
- Stake structure validation
- Emergency functions security
- Ownership management safety

## License
MIT
