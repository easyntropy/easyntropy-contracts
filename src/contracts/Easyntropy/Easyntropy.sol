// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./IEasyntropy.sol";
import "./EasyntropyConsumer.sol";

contract Easyntropy is IEasyntropy {
  address public owner;
  address public vault;
  uint64 public lastRequestId = 0;

  uint256 public fee;
  mapping(address requester => uint256 balance) public balances;
  mapping(address requester => uint256 reservedBalance) public reservedFunds;
  mapping(uint64 requestId => uint256 fee) public requestFees;

  event RequestSubmitted(uint64 indexed requestId, address indexed requester, bytes4 callbackSelector);
  event DepositReceived(address indexed account, uint256 indexed value);
  event FundsWithdrawn(address indexed account, uint256 indexed value);
  error PermissionDenied();
  error NotEasyntropyConsumer();
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
  function requestWithCallback() public payable returns (uint64 requestId) {
    requestId = requestWithCallback(
      0x774358d3 // bytes4(keccak256("easyntropyFulfill(uint64,bytes32)"));
    );
  }

  function requestWithCallback(bytes4 callbackSelector) public payable returns (uint64 requestId) {
    if (balances[msg.sender] < fee) revert NotEnoughEth();

    requestId = ++lastRequestId;

    balances[msg.sender] += msg.value;
    reservedFunds[msg.sender] += fee;
    requestFees[requestId] = fee;

    emit RequestSubmitted(requestId, msg.sender, callbackSelector);
  }

  //
  // rng responses
  function responseWithCallback(
    uint64 requestId,
    address requester,
    bytes4 callbackSelector,
    bytes32 externalSeed,
    uint64 externalSeedId
  ) public onlyVault {
    uint256 requestFee = requestFees[requestId];
    if (balances[requester] < requestFee) revert NotEnoughEth();

    balances[requester] -= requestFee;
    reservedFunds[requester] -= requestFee;
    delete requestFees[requestId];

    payable(vault).transfer(requestFee);

    try EasyntropyConsumer(requester)._easyntropyFulfill(requestId, callbackSelector, externalSeed, externalSeedId) {
    } catch {
      revert NotEasyntropyConsumer();
    }
  }

  //
  // money managment owner
  function setVault(address _vault) public onlyOwner {
    vault = _vault;
  }

  function setFee(uint256 _fee) public onlyOwner {
    fee = _fee;
  }

  //
  // money managment users
  function withdraw(uint256 amount) public {
    if (amount > balances[msg.sender] - reservedFunds[msg.sender]) revert NotEnoughEth();

    balances[msg.sender] -= amount;
    emit FundsWithdrawn(msg.sender, amount);
    payable(msg.sender).transfer(amount);
  }

  function deposit() public payable {
    balances[msg.sender] += msg.value;
    emit DepositReceived(msg.sender, msg.value);
  }

  receive() external payable {
    deposit();
  }
}
