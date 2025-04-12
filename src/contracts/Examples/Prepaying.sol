// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "../Easyntropy/EasyntropyConsumer.sol";

contract Prepaying is EasyntropyConsumer {
  //
  // support
  bytes32 public latestSeed;

  constructor(address _entropy) EasyntropyConsumer(_entropy) {}

  function requestRandomValueWithoutPaying() public returns (uint64 requestId) {
    //
    // calling entropy.requestWithCallback directly without any fee.
    // this is only possible if easyntropyDeposit{ value: ... }() has been called earlier.
    requestId = entropy.requestWithCallback();
  }

  function easyntropyFulfill(uint64, bytes32 seed) external onlyEasyntropy {
    latestSeed = seed;
  }

  //
  // --- optional calculateSeed customisation, simplified for tests -------------
  function calculateSeed(bytes32 externalSeed) internal pure override returns (bytes32 result) {
    result = externalSeed;
  }
}
