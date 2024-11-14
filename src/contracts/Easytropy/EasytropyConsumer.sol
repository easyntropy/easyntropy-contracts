// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./IEasytropy.sol";

abstract contract EasytropyConsumer {
  IEasytropy public entropy;

  event FulfillmentSucceed(
    uint64 indexed sequenceNumber,
    bytes32 seed,
    bytes32 externalSeed,
    uint64 indexed externalSeedId,
    bytes32 internalSeed
  );
  event FulfillmentFailed(
    uint64 indexed sequenceNumber,
    bytes32 seed,
    bytes32 externalSeed,
    uint64 indexed externalSeedId,
    bytes32 internalSeed
  );
  error PermissionDenied();

  modifier onlyEasytropy() {
    if (msg.sender != address(entropy)) revert PermissionDenied();
    _;
  }

  constructor(address _entropy) {
    entropy = IEasytropy(_entropy);
  }

  function _easytropyFulfill(
    uint64 sequenceNumber,
    bytes4 callbackSelector,
    bytes32 externalSeed,
    uint64 externalSeedId
  ) external onlyEasytropy {
    bytes32 internalSeed = calculateInternalSeed();
    bytes32 seed = keccak256(abi.encodePacked(externalSeed, internalSeed));

    bytes4 finalCallbackSelector = callbackSelector;
    if (finalCallbackSelector == 0) {
      finalCallbackSelector = bytes4(keccak256("easytropyFulfill(uint64,bytes32)"));
    }

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = address(this).call(abi.encodeWithSelector(finalCallbackSelector, sequenceNumber, seed));
    if (success) {
      emit FulfillmentSucceed(sequenceNumber, seed, externalSeed, externalSeedId, internalSeed);
    } else {
      emit FulfillmentFailed(sequenceNumber, seed, externalSeed, externalSeedId, internalSeed);
    }
  }

  function calculateInternalSeed() internal view virtual returns (bytes32 result) {
    result = keccak256(abi.encodePacked(block.number, tx.gasprice));
  }
}
