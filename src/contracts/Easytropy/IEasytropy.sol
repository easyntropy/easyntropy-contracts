// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface IEasytropy {
  function getFee() external view returns (uint256 fee);
  function requestWithCallback() external payable returns (uint64 requestId);
  function requestWithCallback(bytes4 callbackSelector) external payable returns (uint64 requestId);
}
