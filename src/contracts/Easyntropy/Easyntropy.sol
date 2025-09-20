// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./IEasyntropy.sol";
import "./IEasyntropyConsumer.sol";

contract Easyntropy is IEasyntropy {
  uint256 public constant RELEASE_FUNDS_AFTER_BLOCKS = 50000; // ~1 week

  address public owner;
  mapping(address executor => bool allowed) public executors;
  uint64 public lastRequestId = 0;

  uint256 public fee;
  mapping(address requester => uint256 balance) public balances;
  mapping(address requester => uint256 reservedFund) public reservedFunds;
  mapping(address requester => uint256 lastResponseBlockNumber) public lastResponses;
  mapping(uint64 requestId => uint256 fee) public requestFees;

  event RequestSubmitted(uint64 indexed requestId, address indexed requester, bytes4 callbackSelector);
  event DepositReceived(address indexed account, uint256 indexed value);
  event FundsWithdrawn(address indexed account, uint256 indexed value);
  event OwnerChanged(address indexed account);
  event ExecutorAdded(address indexed account);
  event ExecutorRemoved(address indexed account);
  event FeeSet(uint256 indexed value);
  error PermissionDenied();
  error NotEnoughEth();

  modifier onlyOwner() {
    if (msg.sender != owner) revert PermissionDenied();
    _;
  }

  modifier onlyExecutor() {
    if (!executors[msg.sender]) revert PermissionDenied();
    _;
  }

  constructor(address executor, uint256 _fee) {
    executors[executor] = true;
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
    balances[msg.sender] += msg.value;
    if (balances[msg.sender] < fee) revert NotEnoughEth();

    requestId = ++lastRequestId;
    reservedFunds[msg.sender] += fee;
    requestFees[requestId] = fee;

    //
    // To allow withdrawal of reserved funds (after the RELEASE_FUNDS_AFTER_BLOCKS period)
    // in case of a response failure on a first request for a given address. We artificially
    // set lastResponses to current block number. For details, examine reservedFundsWaitingPeriod()
    if (lastResponses[msg.sender] == 0) {
      lastResponses[msg.sender] = block.number;
    }

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
  ) public onlyExecutor {
    uint256 requestFee = requestFees[requestId];
    if (balances[requester] < requestFee) revert NotEnoughEth();

    balances[requester] -= requestFee;
    reservedFunds[requester] -= requestFee;
    lastResponses[requester] = block.number;
    delete requestFees[requestId];

    payable(msg.sender).transfer(requestFee);

    IEasyntropyConsumer(requester)._easyntropyFulfill(requestId, callbackSelector, externalSeed, externalSeedId);
  }

  //
  // contract management
  function changeOwner(address newOwner) public onlyOwner {
    owner = newOwner;
    emit OwnerChanged(newOwner);
  }

  function addExecutor(address executor) public onlyOwner {
    executors[executor] = true;
    emit ExecutorAdded(executor);
  }

  function removeExecutor(address executor) public onlyOwner {
    delete executors[executor];
    emit ExecutorRemoved(executor);
  }

  function setFee(uint256 _fee) public onlyOwner {
    fee = _fee;
    emit FeeSet(_fee);
  }

  //
  // users money managment
  function reservedFundsWaitingPeriod(address addr) public view returns (uint256 result) {
    uint256 releaseBlock = lastResponses[addr] + RELEASE_FUNDS_AFTER_BLOCKS;
    return block.number > releaseBlock ? 0 : (releaseBlock - block.number);
  }

  function withdraw(uint256 amount) public {
    // Release reserved funds after RELEASE_FUNDS_AFTER_BLOCKS of oracle inactivity
    // to allow contracts to withdraw all funds in case of a major oracle failure.
    if (reservedFundsWaitingPeriod(msg.sender) == 0) {
      reservedFunds[msg.sender] = 0;
    }

    if (amount > balances[msg.sender] - reservedFunds[msg.sender]) revert NotEnoughEth();

    balances[msg.sender] -= amount;
    payable(msg.sender).transfer(amount);
    emit FundsWithdrawn(msg.sender, amount);
  }

  function deposit() public payable {
    balances[msg.sender] += msg.value;
    emit DepositReceived(msg.sender, msg.value);
  }

  receive() external payable {
    deposit();
  }
}
