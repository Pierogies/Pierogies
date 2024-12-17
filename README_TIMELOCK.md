CreatorTimelock Smart Contract
Overview

The CreatorTimelock contract is designed to lock a specific percentage (10%) of a given token's total supply for a period of 10 years. The locked tokens will be released to a designated creator address after this period.
Features

    Token Lockup: The contract locks a predefined percentage of the total token supply.
    Creator's Release: Only the creator address specified during the contract deployment can release the tokens after the specified release time.
    Emergency Withdrawal: The contract allows for emergency withdrawal of any remaining tokens after the lockup period.
    Events: The contract emits events for transparency—TokensFunded, TokensReleased, and EmergencyWithdrawal.

Constructor Parameters

    _token: The token address to be locked.
    _creator: The address that will receive the locked tokens upon release.
    releaseTime: The timestamp for the release date, set to 10 years from the deployment time.

Functions

    fund(uint256 totalSupply): Locks 10% of the given token's total supply to the contract.
    release(): Allows the creator to release the locked tokens after the specified release time.
    emergencyWithdraw(): Allows the contract owner to withdraw any remaining tokens in case of emergency.
    getRemainingLockedTokens(): Returns the amount of tokens still locked in the contract.

Events

    TokensFunded: Emitted when tokens are locked into the contract.
    TokensReleased: Emitted when tokens are released to the creator.
    EmergencyWithdrawal: Emitted when tokens are withdrawn by the contract owner in an emergency.
