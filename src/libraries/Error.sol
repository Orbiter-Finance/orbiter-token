// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

error NotSupportToken();

error InvalidAddr();
error InvalidAmount();
error InvalidData();

error InsufficientBalance();

// Error when the signature is invalid
error InvalidSignature();

// Error when trying to pause an already paused contract or unpause an already active contract
error InvalidPauseState(bool currentPausedState, bool newPausedState);

// Error when trying to perform an operation when the contract is paused
error ContractPaused();

// Error when current pause state does not match expected pause state
error ContractPausedStateError(bool currentPausedState, bool expectPausedState);

error Timeout();
