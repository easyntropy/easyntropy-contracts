// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "../Easyntropy/EasyntropyConsumer.sol";

contract PassPlayerMetadata is EasyntropyConsumer {
  //
  // support
  struct Gladiator {
    uint8 strength;
  }

  struct RNGRequest {
    uint64 gladiatorId;
  }

  mapping(uint64 gladiatorId => Gladiator gladiator) public gladiators;
  mapping(uint64 requestId => RNGRequest rngRequest) public pendingRequests;
  bytes32 public latestSeed;

  //
  // events & errors
  error NotEnoughEth();

  constructor(address _easyntropy) EasyntropyConsumer(_easyntropy) {
    gladiators[0] = Gladiator({ strength: 1 });
    gladiators[1] = Gladiator({ strength: 1 });
  }

  function startTrainingGladiator(uint64 gladiatorId) public payable returns (uint64 requestId) {
    if (msg.value < easyntropyFee()) revert NotEnoughEth();
    requestId = easyntropyRequestWithCallback(this.trainGladiator.selector);
    pendingRequests[requestId] = RNGRequest({ gladiatorId: gladiatorId });
  }

  function trainGladiator(uint64 requestId, bytes32 seed) external onlyEasyntropy {
    uint256 randomNumber = uint256(seed);
    uint64 gladiatorId = pendingRequests[requestId].gladiatorId;

    gladiators[gladiatorId].strength = uint8(randomNumber & 0xFF);

    delete pendingRequests[requestId];
  }

  //
  // --- optional calculateSeed customisation, simplified for tests -------------
  function calculateSeed(bytes32 externalSeed) internal pure override returns (bytes32 result) {
    result = externalSeed;
  }
}
