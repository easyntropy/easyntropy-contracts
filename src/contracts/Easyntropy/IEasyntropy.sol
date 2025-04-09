// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface IEasyntropy {
  function fee() external view returns (uint256 fee);
  function balances(address addr) external view returns (uint256 balance);
  function deposit() external payable;
  function withdraw(uint256 amount) external;
  function requestWithCallback() external payable returns (uint64 requestId);
  function requestWithCallback(bytes4 callbackSelector) external payable returns (uint64 requestId);
}
