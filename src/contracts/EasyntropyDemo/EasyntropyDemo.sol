// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "../Easyntropy/EasyntropyConsumer.sol";

contract EasyntropyDemo is EasyntropyConsumer {
  //
  // support
  mapping(uint64 sequenceNumber => bool dummy) public pendingRequests;
  bytes32 public latestSeed;

  //
  // events & errors
  event RandomValueRequested(uint64 indexed sequenceNumber);
  event RandomValueObtained(uint64 indexed sequenceNumber, bytes32 seed);
  error NotEnoughEth();

  constructor(address _entropy) EasyntropyConsumer(_entropy) {}

  //
  // entropy demo default fulfill callback
  function requestRandomValue() public payable returns (uint64 sequenceNumber) {
    uint256 entropyRequestFee = entropyFee();
    if (msg.value < entropyRequestFee) revert NotEnoughEth();

    sequenceNumber = entropy.requestWithCallback{ value: entropyRequestFee }();

    pendingRequests[sequenceNumber] = true;

    emit RandomValueRequested(sequenceNumber);
  }

  function easyntropyFulfill(uint64 sequenceNumber, bytes32 seed) external onlyEasyntropy {
    delete pendingRequests[sequenceNumber];
    latestSeed = seed;

    emit RandomValueObtained(sequenceNumber, seed);
  }

  //
  // entropy demo custom fulfill callback
  function requestRandomValueCustomCallback() public payable returns (uint64 sequenceNumber) {
    uint256 entropyRequestFee = entropyFee();
    if (msg.value < entropyRequestFee) revert NotEnoughEth();

    sequenceNumber = entropy.requestWithCallback{ value: entropyRequestFee }(this.customFulfill.selector);

    pendingRequests[sequenceNumber] = true;

    emit RandomValueRequested(sequenceNumber);
  }

  function customFulfill(uint64 sequenceNumber, bytes32 seed) external onlyEasyntropy {
    delete pendingRequests[sequenceNumber];

    latestSeed = seed;

    emit RandomValueObtained(sequenceNumber, seed);
  }

  function calculateSeed(bytes32 externalSeed) internal pure override returns (bytes32 result) {
    result = externalSeed;
  }

  //
  // money managment
  receive() external payable {}
}
