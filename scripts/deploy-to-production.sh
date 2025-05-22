#!/bin/bash

PRIVATE_KEY="..."
ETHERSCAN_API_KEY="..."

RPC_URL=https://ethereum.publicnode.com/
EXECUTOR_ADDRESS=0x147ca77892290B5103fE10299A6DEe74321c1447
FEE_AMOUNT=$(cast to-wei 0.0002 ether)

forge create \
  ./src/contracts/Easyntropy/Easyntropy.sol:Easyntropy \
  --rpc-url $RPC_URL \
  --broadcast \
  --private-key $PRIVATE_KEY \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args $EXECUTOR_ADDRESS $FEE_AMOUNT
