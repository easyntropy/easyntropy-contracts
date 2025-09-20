// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./IEasyntropy.sol";
import "./IEasyntropyConsumer.sol";

abstract contract EasyntropyConsumer is IEasyntropyConsumer {
  IEasyntropy public easyntropy;

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

  modifier _onlyEasyntropyOracle() {
    if (msg.sender != address(easyntropy)) revert PermissionDenied();
    _;
  }

  constructor(address _easyntropy) {
    easyntropy = IEasyntropy(_easyntropy);
  }

  //
  // calculates the final seed.
  //
  // The externalSeed is the same for everyone within a single drand.love time window
  // (approximately 3 seconds), so we need our own semi-random component. By default, this method
  // is called to compute the final seed. If there are project-specific variables (for example, a
  // player ID), feel free to override this method to incorporate them.
  function calculateSeed(bytes32 externalSeed) internal view virtual returns (bytes32 result) {
    result = keccak256(abi.encodePacked(externalSeed, blockhash(block.number - 1), tx.gasprice));
  }

  //
  // utils
  function easyntropyFee() public view returns (uint256 fee) {
    fee = easyntropy.fee();
  }

  function easyntropyCurrentBalance() public view returns (uint256 balance) {
    balance = easyntropy.balances(address(this));
  }

  function easyntropyDeposit() public payable {
    easyntropy.deposit{ value: msg.value }();
  }

  function easyntropyWithdraw(uint256 amount) internal {
    easyntropy.withdraw(amount);
  }

  //
  // request handling
  function easyntropyRequestWithCallback() internal returns (uint64 requestId) {
    requestId = easyntropy.requestWithCallback{ value: easyntropyFee() }();
  }

  function easyntropyRequestWithCallback(bytes4 callbackSelector) internal returns (uint64 requestId) {
    requestId = easyntropy.requestWithCallback{ value: easyntropyFee() }(callbackSelector);
  }

  //
  // response handling
  function _easyntropyFulfill(
    uint64 requestId,
    bytes4 callbackSelector,
    bytes32 externalSeed,
    uint64 externalSeedId
  ) external _onlyEasyntropyOracle {
    bytes32 seed = calculateSeed(externalSeed);

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = address(this).call(abi.encodeWithSelector(callbackSelector, requestId, seed));
    if (success) {
      emit FulfillmentSucceeded(requestId, address(this), seed, externalSeed, externalSeedId);
    } else {
      emit FulfillmentFailed(requestId, address(this), seed, externalSeed, externalSeedId);
    }
  }
}
