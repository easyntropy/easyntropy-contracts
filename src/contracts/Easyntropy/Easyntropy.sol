// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./IEasyntropy.sol";
import "./EasyntropyConsumer.sol";

contract Easyntropy is IEasyntropy {
  uint256 public fee;
  uint64 public requestId = 0;
  address public owner;
  address public vault;

  event RequestSubmitted(uint64 indexed requestId, address indexed requester, bytes4 callbackSelector);
  error PermissionDenied();
  error NotEnoughEth();

  modifier onlyOwner() {
    if (msg.sender != owner) revert PermissionDenied();
    _;
  }

  modifier onlyVault() {
    if (msg.sender != vault) revert PermissionDenied();
    _;
  }

  constructor(address _vault, uint256 _fee) {
    vault = _vault;
    fee = _fee;
    owner = msg.sender;
  }

  //
  // RNG requests
  function requestWithCallback() external payable returns (uint64 returnedRequestId) {
    if (msg.value < fee) revert NotEnoughEth();

    returnedRequestId = ++requestId;
    payable(vault).transfer(msg.value);

    emit RequestSubmitted(
      returnedRequestId,
      msg.sender,
      0x774358d3 // bytes4(keccak256("easyntropyFulfill(uint64,bytes32)"));
    );
  }

  function requestWithCallback(bytes4 callbackSelector) external payable returns (uint64 returnedRequestId) {
    if (msg.value < fee) revert NotEnoughEth();

    returnedRequestId = ++requestId;
    payable(vault).transfer(msg.value);

    emit RequestSubmitted(returnedRequestId, msg.sender, callbackSelector);
  }

  //
  // rng responses
  function responseWithCallback(
    uint64 sequenceNumber,
    address requester,
    bytes4 callbackSelector,
    bytes32 externalSeed,
    uint64 externalSeedId
  ) public onlyVault {
    EasyntropyConsumer(requester)._easyntropyFulfill(sequenceNumber, callbackSelector, externalSeed, externalSeedId);
  }

  //
  // money managment
  function setVault(address _vault) public onlyOwner {
    vault = _vault;
  }

  function setFee(uint256 _fee) public onlyOwner {
    fee = _fee;
  }

  function withdraw(uint256 amount) public onlyOwner {
    payable(owner).transfer(amount);
  }
  receive() external payable {}
}
