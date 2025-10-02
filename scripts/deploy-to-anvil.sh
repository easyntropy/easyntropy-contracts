#!/bin/bash

EXECUTOR_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 # first Anvil user
FEE_AMOUNT=$(cast to-wei 0.002 ether)

forge create \
  ./src/contracts/Easyntropy/Easyntropy.sol:Easyntropy \
  --broadcast \
  --unlocked \
  --from $EXECUTOR_ADDRESS \
  --constructor-args $EXECUTOR_ADDRESS $FEE_AMOUNT

forge create \
  ./src/contracts/Examples/MultiRequest.sol:MultiRequest \
  --broadcast \
  --unlocked \
  --from $EXECUTOR_ADDRESS \
  --constructor-args "0x5FbDB2315678afecb367f032d93F642f64180aa3"
