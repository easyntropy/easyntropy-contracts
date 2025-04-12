// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "../Easyntropy/EasyntropyConsumer.sol";

contract StoreLastSeedCustomCallback is EasyntropyConsumer {
  //
  // support
  bytes32 public latestSeed;

  //
  // events & errors
  event RandomValueRequested(uint64 indexed requestId);
  event RandomValueObtained(uint64 indexed requestId, bytes32 seed);
  error NotEnoughEth();

  constructor(address _entropy) EasyntropyConsumer(_entropy) {}

  function requestRandomValueCustomCallback() public payable returns (uint64 requestId) {
    if (msg.value < easyntropyFee()) revert NotEnoughEth();

    requestId = easyntropyRequestWithCallback(this.customFulfill.selector);

    emit RandomValueRequested(requestId);
  }

  function customFulfill(uint64 requestId, bytes32 seed) external onlyEasyntropy {
    latestSeed = seed;

    emit RandomValueObtained(requestId, seed);
  }

  //
  // --- optional calculateSeed customisation, simplified for tests -------------
  function calculateSeed(bytes32 externalSeed) internal pure override returns (bytes32 result) {
    result = externalSeed;
  }
}
