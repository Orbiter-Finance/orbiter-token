#!/bin/bash
source .env
forge clean &&  forge script script/mintOrbiterToken.s.sol --broadcast -vvvv --rpc-url $ETHEREUM_SEPOLIA_RPC_URL