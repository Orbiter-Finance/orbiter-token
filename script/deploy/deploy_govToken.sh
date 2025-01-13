#!/bin/bash
source .env
forge clean &&  forge script script/deployGovToken.s.sol --broadcast -vvvv --rpc-url $ETHEREUM_SEPOLIA_RPC_URL 