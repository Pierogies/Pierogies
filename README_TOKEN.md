
# BEP20 Token Contract - "Pierogies" (PIRGS)

This repository contains the implementation of the BEP20 token "Pierogies" (symbol: PIRGS).

## Overview

- **Name**: Pierogies
- **Symbol**: PIRGS
- **Decimals**: 18
- **Initial Supply**: 1,000,000,000,000 (1 Trillion tokens)
- **Standard**: BEP20 (compatible with ERC20)

The contract includes the basic functionality of a BEP20 token with the ability to transfer, approve, and burn tokens.

## Features

1. **Transfer Tokens**: Users can transfer tokens to other addresses.
2. **Approve Allowances**: Token holders can approve other addresses to spend tokens on their behalf.
3. **Burn Tokens**: Users can permanently destroy their tokens, reducing the total supply.
4. **Ownership**: The deploying address is set as the owner, holding the initial supply.

## Functions

### Core BEP20 Functions

- `totalSupply()`: Returns the total supply of tokens.
- `balanceOf(address account)`: Returns the token balance of a specific account.
- `transfer(address recipient, uint256 amount)`: Transfers tokens from the caller to the recipient.
- `allowance(address owner, address spender)`: Returns the remaining number of tokens that `spender` is allowed to spend on behalf of `owner`.
- `approve(address spender, uint256 amount)`: Sets the amount of tokens that a spender is allowed to spend on behalf of the caller.
- `transferFrom(address sender, address recipient, uint256 amount)`: Transfers tokens on behalf of `sender` to `recipient`.

### Additional Functions

- `burn(uint256 amount)`: Allows token holders to destroy a specified number of tokens, reducing the total supply.

## Deployment

The contract is implemented in Solidity version `0.8.26`. To deploy:

1. Use a development environment such as [Remix](https://remix.ethereum.org) or [Hardhat](https://hardhat.org).
2. Ensure you have the required compiler version (`^0.8.26`).
3. Deploy the contract to a compatible blockchain (e.g., Binance Smart Chain).

## Usage

1. **Minted Supply**: Upon deployment, the total supply of tokens is minted and assigned to the deployer's address.
2. **Token Transfers**: Tokens can be transferred between users.
3. **Burn Tokens**: Users can burn tokens to reduce the total supply.

## Example Interaction

### Transfer Tokens

```solidity
// Transfer 100 PIRGS from the caller to a recipient
token.transfer(recipientAddress, 100 * 10**18);
```

### Approve and TransferFrom

```solidity
// Approve another address to spend 50 PIRGS on behalf of the caller
token.approve(spenderAddress, 50 * 10**18);

// Transfer 50 PIRGS from the caller to the recipient using allowance
token.transferFrom(callerAddress, recipientAddress, 50 * 10**18);
```

### Burn Tokens

```solidity
// Burn 10 PIRGS from the caller's balance
token.burn(10 * 10**18);
```

## Security

This contract follows standard practices for BEP20 token implementation. However, we ensured it thorough testing and auditing before deployment.

---

**Disclaimer**: Use this code at your own risk. The authors are not responsible for any losses incurred through the use of this smart contract.
