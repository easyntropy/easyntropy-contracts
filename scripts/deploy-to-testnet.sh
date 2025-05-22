#!/bin/bash

PRIVATE_KEY="..."
ETHERSCAN_API_KEY="..."

RPC_URL=https://sepolia.drpc.org
EXECUTOR_ADDRESS=0x7024f2a7d9580098dD06A8675E912f6CBcC4fB0A
FEE_AMOUNT=$(cast to-wei 0.00001 ether)

forge create \
  ./src/contracts/Easyntropy/Easyntropy.sol:Easyntropy \
  --rpc-url $RPC_URL \
  --broadcast \
  --private-key $PRIVATE_KEY \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args $EXECUTOR_ADDRESS $FEE_AMOUNT
