#!/bin/bash

PRIVATE_KEY="..."
ETHERSCAN_API_KEY="..."

RPC_URL=https://sepolia.drpc.org
EXECUTOR_ADDRESS=0x4c286B50c4407FeBcB3FFf935d92bB1480845129
FEE_AMOUNT=$(cast to-wei 0.00001 ether)

forge create \
  ./src/contracts/Easyntropy/Easyntropy.sol:Easyntropy \
  --rpc-url $RPC_URL \
  --broadcast \
  --private-key $PRIVATE_KEY \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args $EXECUTOR_ADDRESS $FEE_AMOUNT
