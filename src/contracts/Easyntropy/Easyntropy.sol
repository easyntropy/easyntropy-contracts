// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./IEasyntropy.sol";

contract Easyntropy is IEasyntropy {
  uint256 public fee;
  uint64 public requestId = 0;
  address public owner;

  event RequestSubmitted(uint64 indexed requestId, address indexed requester, bytes4 callbackSelector);
  error PermissionDenied();
  error NotEnoughEth();

  modifier onlyOwner() {
    if (msg.sender != owner) revert PermissionDenied();
    _;
  }

  constructor(uint256 initialFee) {
    fee = initialFee;
    owner = msg.sender;
  }

  //
  // fee managment
  function setFee(uint256 _fee) public onlyOwner {
    fee = _fee;
  }

  //
  // RNG requests
  function requestWithCallback() external payable returns (uint64 returnedRequestId) {
    if (msg.value < fee) revert NotEnoughEth();
    returnedRequestId = ++requestId;

    bytes4 callbackSelector = bytes4(keccak256("easyntropyFulfill(uint64,bytes32)"));

    emit RequestSubmitted(returnedRequestId, msg.sender, callbackSelector);
  }

  function requestWithCallback(bytes4 callbackSelector) external payable returns (uint64 returnedRequestId) {
    if (msg.value < fee) revert NotEnoughEth();
    returnedRequestId = ++requestId;

    emit RequestSubmitted(returnedRequestId, msg.sender, callbackSelector);
  }

  //
  // money managment
  function withdraw(uint256 amount) public onlyOwner {
    payable(owner).transfer(amount);
  }
  receive() external payable {}
}
