#!/bin/bash
source .env
forge clean &&  forge script script/deployLockedTokenGov.s.sol --broadcast -vvvv --rpc-url $ETHEREUM_SEPOLIA_RPC_URL 