// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "../Easyntropy/EasyntropyConsumer.sol";

contract EasyntropyDemo is EasyntropyConsumer {
  //
  // support
  mapping(uint64 requestId => bool dummy) public pendingRequests;
  bytes32 public latestSeed;

  //
  // events & errors
  event RandomValueRequested(uint64 indexed requestId);
  event RandomValueObtained(uint64 indexed requestId, bytes32 seed);
  error NotEnoughEth();

  constructor(address _entropy) EasyntropyConsumer(_entropy) {}

  //
  // entropy demo default fulfill callback
  function requestRandomValue() public payable returns (uint64 requestId) {
    uint256 entropyRequestFee = entropyFee();
    if (msg.value < entropyRequestFee) revert NotEnoughEth();

    requestId = entropy.requestWithCallback{ value: entropyRequestFee }();

    pendingRequests[requestId] = true;

    emit RandomValueRequested(requestId);
  }

  function easyntropyFulfill(uint64 requestId, bytes32 seed) external onlyEasyntropy {
    delete pendingRequests[requestId];
    latestSeed = seed;

    emit RandomValueObtained(requestId, seed);
  }

  //
  // entropy demo custom fulfill callback
  function requestRandomValueCustomCallback() public payable returns (uint64 requestId) {
    uint256 entropyRequestFee = entropyFee();
    if (msg.value < entropyRequestFee) revert NotEnoughEth();

    requestId = entropy.requestWithCallback{ value: entropyRequestFee }(this.customFulfill.selector);

    pendingRequests[requestId] = true;

    emit RandomValueRequested(requestId);
  }

  function customFulfill(uint64 requestId, bytes32 seed) external onlyEasyntropy {
    delete pendingRequests[requestId];

    latestSeed = seed;

    emit RandomValueObtained(requestId, seed);
  }

  function calculateSeed(bytes32 externalSeed) internal pure override returns (bytes32 result) {
    result = externalSeed;
  }

  //
  // money managment
  receive() external payable {}
}
