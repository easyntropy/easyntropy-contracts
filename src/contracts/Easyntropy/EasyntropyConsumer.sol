// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./IEasyntropy.sol";

abstract contract EasyntropyConsumer {
  IEasyntropy public entropy;

  event FulfillmentSucceed(
    uint64 indexed sequenceNumber,
    address indexed requester,
    bytes32 seed,
    bytes32 externalSeed,
    uint64 indexed externalSeedId,
    bytes32 internalSeed
  );
  event FulfillmentFailed(
    uint64 indexed sequenceNumber,
    address indexed requester,
    bytes32 seed,
    bytes32 externalSeed,
    uint64 indexed externalSeedId,
    bytes32 internalSeed
  );
  error PermissionDenied();

  modifier onlyEasyntropy() {
    if (msg.sender != address(entropy)) revert PermissionDenied();
    _;
  }

  constructor(address _entropy) {
    entropy = IEasyntropy(_entropy);
  }

  function _easyntropyFulfill(
    uint64 sequenceNumber,
    bytes4 callbackSelector,
    bytes32 externalSeed,
    uint64 externalSeedId
  ) external onlyEasyntropy {
    bytes32 internalSeed = calculateInternalSeed();
    bytes32 seed = keccak256(abi.encodePacked(externalSeed, internalSeed));

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = address(this).call(abi.encodeWithSelector(callbackSelector, sequenceNumber, seed));
    if (success) {
      emit FulfillmentSucceed(sequenceNumber, address(this), seed, externalSeed, externalSeedId, internalSeed);
    } else {
      emit FulfillmentFailed(sequenceNumber, address(this), seed, externalSeed, externalSeedId, internalSeed);
    }
  }

  function calculateInternalSeed() internal view virtual returns (bytes32 result) {
    result = keccak256(abi.encodePacked(block.number, tx.gasprice));
  }
}
