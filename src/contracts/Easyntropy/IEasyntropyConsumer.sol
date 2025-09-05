// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./IEasyntropy.sol";

interface IEasyntropyConsumer {
  function entropy() external view returns (IEasyntropy entropy);
  function easyntropyFee() external view returns (uint256 fee);
  function easyntropyCurrentBalance() external view returns (uint256 balance);
  function easyntropyDeposit() external payable;
  function _easyntropyFulfill(uint64 requestId, bytes4 callbackSelector, bytes32 externalSeed, uint64 externalSeedId) external;
}
