// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./IEasyntropy.sol";
import "./IEasyntropyConsumer.sol";

abstract contract EasyntropyConsumer is IEasyntropyConsumer {
  IEasyntropy public easyntropy;

  event FulfillmentSucceeded(uint64 indexed requestId, address indexed requester, bytes32 seed, bytes32 easyntropySeed);
  event FulfillmentFailed(uint64 indexed requestId, address indexed requester, bytes32 seed, bytes32 easyntropySeed);
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
  // Calculate the final seed.
  // If you want to introduce your own semi-random component
  // (for example, a player ID in some game, etc.), feel free
  // to override this method.
  function calculateSeed(uint64 requestId, bytes32 easyntropySeed) internal view virtual returns (bytes32 result) {
    result = keccak256(abi.encodePacked(requestId, easyntropySeed, blockhash(block.number - 1), tx.gasprice));
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
  function _easyntropyFulfill(uint64 requestId, bytes4 callbackSelector, bytes32 easyntropySeed) external _onlyEasyntropyOracle {
    bytes32 seed = calculateSeed(requestId, easyntropySeed);

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = address(this).call(abi.encodeWithSelector(callbackSelector, requestId, seed));
    if (success) {
      emit FulfillmentSucceeded(requestId, address(this), seed, easyntropySeed);
    } else {
      emit FulfillmentFailed(requestId, address(this), seed, easyntropySeed);
    }
  }
}
