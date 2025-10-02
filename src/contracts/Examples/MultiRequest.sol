// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "../Easyntropy/EasyntropyConsumer.sol";

contract MultiRequest is EasyntropyConsumer {
  //
  // support
  struct RNGRequest {
    uint256 callId;
  }

  uint256 public currentCallId = 0;
  mapping(uint256 callId => bytes32 seed) public seeds;
  mapping(uint64 requestId => RNGRequest rngRequest) public pendingRequests;

  //
  // events & errors
  event RandomValueRequested(uint64 indexed requestId);
  event RandomValueObtained(uint64 indexed requestId, bytes32 seed);
  error NotEnoughEth();

  constructor(address _easyntropy) EasyntropyConsumer(_easyntropy) {}

  function calculateFee(uint256 count) public view returns (uint256 result) {
    result = count * easyntropyFee();
  }

  function requestRandomValues(uint256 count) public payable {
    uint256 totalFee = count * easyntropyFee();
    if (msg.value < totalFee) revert NotEnoughEth();

    for (uint256 i = 0; i < count; ++i) {
      ++currentCallId;
      uint64 requestId = easyntropyRequestWithCallback();
      pendingRequests[requestId] = RNGRequest({ callId: currentCallId });
      emit RandomValueRequested(requestId);
    }
  }

  function easyntropyFulfill(uint64 requestId, bytes32 seed) external onlyEasyntropy {
    uint256 callId = pendingRequests[requestId].callId;
    seeds[callId] = seed;

    emit RandomValueObtained(requestId, seed);
    delete pendingRequests[requestId];
  }

  //
  // --- optional calculateSeed customisation, simplified for tests -------------
  function calculateSeed(uint64, bytes32 easyntropySeed) internal pure override returns (bytes32 result) {
    result = easyntropySeed;
  }
}
