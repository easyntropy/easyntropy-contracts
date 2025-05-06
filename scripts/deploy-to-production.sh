#!/bin/bash

RPC_URL=https://sepolia.drpc.org
EXECUTOR_ADDRESS=0x147ca77892290B5103fE10299A6DEe74321c1447
FEE_AMOUNT=$(cast to-wei 0.00001 ether)

forge build

BASE_BYTECODE=$(forge inspect Easyntropy bytecode)
CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address,uint256)" $EXECUTOR_ADDRESS $FEE_AMOUNT)

DEPLOYMENT_BYTECODE="${BASE_BYTECODE}${CONSTRUCTOR_ARGS:2}"  # Remove '0x' prefix from args

echo "Contract deployment bytecode (use this as data in MetaMask):"
echo "0x$DEPLOYMENT_BYTECODE"
