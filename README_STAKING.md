
# Staking Contract

This repository contains a simple staking contract written in Solidity for the Ethereum Virtual Machine (EVM).

## Features
- Stake tokens for fixed durations (1 month, 6 months, 12 months) with variable APY.
- Calculate and claim rewards after the staking period.
- Admin functionalities for recovering tokens and migrating stakes.

## How to Use
1. Deploy the contract by providing the address of the token to be staked.
2. Use the `stake` function to stake tokens by specifying the amount and duration.
3. Use the `unstake` function to withdraw staked tokens along with rewards after the lock period.
4. Admin can recover accidentally sent tokens using `recoverERC20`.

## APY Rates
- **1 Month**: 10% APY
- **6 Months**: 20% APY
- **12 Months**: 30% APY

## Security Features
- Implements reentrancy protection using OpenZeppelin's `ReentrancyGuard`.
- Owner-only functions are secured with `Ownable`.

## Dependencies
- OpenZeppelin Contracts: `@openzeppelin/contracts`
- Solidity version: `^0.8.26`

## License
This project is licensed under the MIT License.
