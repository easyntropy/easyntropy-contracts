// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./IEasyntropy.sol";

abstract contract EasyntropyConsumer {
  IEasyntropy public entropy;

  event FulfillmentSucceeded(
    uint64 indexed requestId,
    address indexed requester,
    bytes32 seed,
    bytes32 externalSeed,
    uint64 indexed externalSeedId
  );
  event FulfillmentFailed(
    uint64 indexed requestId,
    address indexed requester,
    bytes32 seed,
    bytes32 externalSeed,
    uint64 indexed externalSeedId
  );
  error PermissionDenied();

  modifier onlyEasyntropy() {
    if (msg.sender != address(this)) revert PermissionDenied();
    _;
  }

  modifier onlyEasyntropyOracle() {
    if (msg.sender != address(entropy)) revert PermissionDenied();
    _;
  }

  constructor(address _entropy) {
    entropy = IEasyntropy(_entropy);
  }

  function entropyFee() public view returns (uint256 fee) {
    fee = entropy.fee();
  }

  // request handling
  function entropyRequestWithCallback() internal returns (uint64 requestId) {
    requestId = entropy.requestWithCallback{ value: entropyFee() }();
  }

  function entropyRequestWithCallback(bytes4 callbackSelector) internal returns (uint64 requestId) {
    requestId = entropy.requestWithCallback{ value: entropyFee() }(callbackSelector);
  }

  // response handling
  function _easyntropyFulfill(
    uint64 requestId,
    bytes4 callbackSelector,
    bytes32 externalSeed,
    uint64 externalSeedId
  ) external onlyEasyntropyOracle {
    bytes32 seed = calculateSeed(externalSeed);

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = address(this).call(abi.encodeWithSelector(callbackSelector, requestId, seed));
    if (success) {
      emit FulfillmentSucceeded(requestId, address(this), seed, externalSeed, externalSeedId);
    } else {
      emit FulfillmentFailed(requestId, address(this), seed, externalSeed, externalSeedId);
    }
  }

  function calculateSeed(bytes32 externalSeed) internal view virtual returns (bytes32 result) {
    result = keccak256(abi.encodePacked(externalSeed, block.number, tx.gasprice));
  }
}
