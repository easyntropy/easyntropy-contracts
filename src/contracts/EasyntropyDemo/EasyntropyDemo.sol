// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "../Easyntropy/EasyntropyConsumer.sol";

contract EasyntropyDemo is EasyntropyConsumer {
  //
  // support
  mapping(uint64 sequenceNumber => bool dummy) public pendingRequests;

  //
  // events & errors
  event RandomNumberRequested(uint64 indexed sequenceNumber);
  event RandomNumberObtained(uint64 indexed sequenceNumber, bytes32 seed);
  error NotEnoughEth();

  constructor(address _entropy) EasyntropyConsumer(_entropy) {}

  //
  // entropy demo
  function requestRandomNumber() public payable {
    uint256 entropyRequestFee = entropy.getFee();
    if (msg.value < entropyRequestFee) revert NotEnoughEth();

    uint64 sequenceNumber = entropy.requestWithCallback{ value: entropyRequestFee }();

    pendingRequests[sequenceNumber] = true;

    emit RandomNumberRequested(sequenceNumber);
  }

  function easyntropyFulfill(uint64 sequenceNumber, bytes32 seed) public onlyEasyntropy {
    delete pendingRequests[sequenceNumber];

    emit RandomNumberObtained(sequenceNumber, seed);
  }

  //
  // money managment
  receive() external payable {}
}
