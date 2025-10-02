#!/bin/bash

PRIVATE_KEY="..."
ETHERSCAN_API_KEY="..."

RPC_URL=https://sepolia.drpc.org
EASYNTROPY_ORACLE_ADDRESS=0x62AdC8dd46E71E6dc04A8EC5304e9E9521A9D436

forge create \
  ./src/contracts/Examples/StoreLastSeedDefaultCallback.sol:StoreLastSeedDefaultCallback \
  --rpc-url $RPC_URL \
  --broadcast \
  --private-key $PRIVATE_KEY \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args $EASYNTROPY_ORACLE_ADDRESS
