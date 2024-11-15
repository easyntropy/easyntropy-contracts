// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./IEasyntropy.sol";

contract Easyntropy is IEasyntropy {
  address private owner;
  uint256 private fee;
  uint64 public requestId = 0;

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

  function getFee() external view returns (uint256 result) {
    result = fee;
  }

  //
  // RNG requests
  function requestWithCallback() external payable returns (uint64 returnedRequestId) {
    bytes4 callbackSelector = bytes4(keccak256("easyntropyFulfill(uint64,bytes32)"));
    returnedRequestId = this.requestWithCallback(callbackSelector);
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
