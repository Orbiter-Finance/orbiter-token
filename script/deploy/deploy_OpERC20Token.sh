#!/bin/bash
source .env
forge clean &&  forge script script/deployOpERC20Token.s.sol --broadcast -vvvv --rpc-url $BASE_SEPOLIA_RPC_URL 