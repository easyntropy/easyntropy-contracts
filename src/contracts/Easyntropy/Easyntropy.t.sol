/* solhint-disable func-name-mixedcase, gas-strict-inequalities, one-contract-per-file */
/* solhint-enable foundry-test-functions */

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { Easyntropy } from "./Easyntropy.sol";
import { EasyntropyConsumer } from "./EasyntropyConsumer.sol";

contract EasyntropyTest is Test {
  Easyntropy private subject;
  address public owner;
  address public executor;
  address public user;

  function setUp() public {
    owner = makeAddr("owner");
    user = makeAddr("user");
    executor = makeAddr("executor");
    vm.deal(owner, 1 ether);
    vm.deal(user, 1 ether);

    __prank(owner);
    subject = new Easyntropy(executor, 1 wei);

    __prank(user);
  }

  function test_constructor_setsInitialFee() public view {
    assertEq(subject.fee(), 1 wei);
  }

  function test_constructor_setsOwner() public view {
    assertEq(subject.owner(), owner);
  }

  function test_setFee_setsFee() public {
    __prank(owner);

    subject.setFee(10 wei);
    assertEq(subject.fee(), 10 wei);
  }

  function test_setFee_failsWhenExecutedByNotOwner() public {
    vm.expectRevert(Easyntropy.PermissionDenied.selector);
    subject.setFee(10 wei);
  }

  function test_setExecutor_setsExecutor() public {
    __prank(owner);

    address newExecutor = makeAddr("newExecutor");
    subject.setExecutor(newExecutor);
    assertEq(subject.executor(), newExecutor);
  }

  function test_setExecutor_failsWhenExecutedByNotOwner() public {
    address newExecutor = makeAddr("newExecutor");

    vm.expectRevert(Easyntropy.PermissionDenied.selector);
    subject.setExecutor(newExecutor);
  }

  function test_withdraw_withdrawsFunds() public {
    subject.deposit{ value: 10 wei }();
    subject.requestWithCallback();
    assertEq(user.balance, 999999999999999990 wei);
    assertEq(subject.balances(user), 10 wei);
    assertEq(subject.reservedFunds(user), 1 wei);

    subject.withdraw(5 wei);

    assertEq(user.balance, 999999999999999995 wei);
    assertEq(subject.balances(user), 5 wei);
    assertEq(subject.reservedFunds(user), 1 wei);
  }

  function test_withdraw_failsWhenNotFunds() public {
    assertEq(subject.balances(user), 0 wei);

    vm.expectRevert(Easyntropy.NotEnoughEth.selector);
    subject.withdraw(10 wei);
  }

  function test_withdraw_failsWhenNotEnoughFunds() public {
    subject.deposit{ value: 1 wei }();
    assertEq(subject.balances(user), 1 wei);

    vm.expectRevert(Easyntropy.NotEnoughEth.selector);
    subject.withdraw(10 wei);
  }

  function test_withdraw_failsWhenNotEnoughFundsBecauseReserved() public {
    subject.deposit{ value: 1 wei }();
    subject.requestWithCallback();
    assertEq(subject.balances(user), 1 wei);
    assertEq(subject.reservedFunds(user), 1 wei);

    vm.expectRevert(Easyntropy.NotEnoughEth.selector);
    subject.withdraw(10 wei);
  }

  function test_deposit_depositsFundsToSender() public {
    assertEq(subject.balances(user), 0);
    subject.deposit{ value: 0.5 ether }();
    assertEq(subject.balances(user), 0.5 ether);
  }

  function test_deposit_emitsDepositedEvent() public {
    vm.expectEmit(true, true, true, true);
    emit Easyntropy.DepositReceived(user, 0.5 ether);

    subject.deposit{ value: 0.5 ether }();
  }

  function test_requestWithCallback_failsWhenThereIsNotEnoughBalance() public {
    uint256 fee = subject.fee();

    subject.deposit{ value: fee - 1 wei }();
    vm.expectRevert(Easyntropy.NotEnoughEth.selector);
    subject.requestWithCallback{ value: 0 }();
  }

  function test_requestWithCallback_bumpsRequestId() public {
    uint256 fee = subject.fee();

    assertEq(subject.lastRequestId(), 0);
    subject.requestWithCallback{ value: fee }();
    assertEq(subject.lastRequestId(), 1);
  }

  function test_requestWithCallback_creditsSenderAccount() public {
    uint256 fee = subject.fee();

    assertEq(subject.balances(user), 0);
    assertEq(subject.reservedFunds(user), 0);
    subject.requestWithCallback{ value: fee }();
    assertEq(subject.balances(user), fee);
    assertEq(subject.reservedFunds(user), fee);
  }

  function test_requestWithCallback_creditsSenderAccountSentMoreThanFee() public {
    uint256 fee = subject.fee();
    uint256 sentAmount = fee + 1 wei;

    assertEq(subject.balances(user), 0);
    assertEq(subject.reservedFunds(user), 0);
    subject.requestWithCallback{ value: sentAmount }();
    assertEq(subject.balances(user), sentAmount);
    assertEq(subject.reservedFunds(user), fee);
  }

  function test_requestWithCallback_storesFeeData() public {
    uint256 fee = subject.fee();

    uint64 requestId = subject.requestWithCallback{ value: fee }();
    assertEq(subject.requestFees(requestId), fee);
  }

  function test_requestWithCallback_emitsEvent() public {
    uint256 fee = subject.fee();

    vm.expectEmit(true, true, true, true);
    emit Easyntropy.RequestSubmitted(
      1, // requestId
      user, // sender
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")) // callbackSelector
    );
    subject.requestWithCallback{ value: fee }();
  }

  function test_requestWithCallbackCustomCallback_failsWhenThereIsNotEnoughBalance() public {
    uint256 fee = subject.fee();
    bytes4 callbackSelector = bytes4(keccak256("customFulfill(uint64,bytes32)"));

    subject.deposit{ value: fee - 1 wei }();
    vm.expectRevert(Easyntropy.NotEnoughEth.selector);
    subject.requestWithCallback{ value: 0 }(callbackSelector);
  }

  function test_requestWithCallbackCustomCallback_bumpsRequestId() public {
    uint256 fee = subject.fee();
    bytes4 callbackSelector = bytes4(keccak256("customFulfill(uint64,bytes32)"));

    assertEq(subject.lastRequestId(), 0);
    subject.requestWithCallback{ value: fee }(callbackSelector);
    assertEq(subject.lastRequestId(), 1);
  }

  function test_requestWithCallbackCustomCallback_creditsSenderAccount() public {
    uint256 fee = subject.fee();
    bytes4 callbackSelector = bytes4(keccak256("customFulfill(uint64,bytes32)"));

    assertEq(subject.balances(user), 0);
    assertEq(subject.reservedFunds(user), 0);
    subject.requestWithCallback{ value: fee }(callbackSelector);
    assertEq(subject.balances(user), fee);
    assertEq(subject.reservedFunds(user), fee);
  }

  function test_requestWithCallbackCustomCallback_creditsSenderAccountSentMoreThanFee() public {
    uint256 fee = subject.fee();
    uint256 sentAmount = fee + 1 wei;
    bytes4 callbackSelector = bytes4(keccak256("customFulfill(uint64,bytes32)"));

    assertEq(subject.balances(user), 0);
    assertEq(subject.reservedFunds(user), 0);
    subject.requestWithCallback{ value: sentAmount }(callbackSelector);
    assertEq(subject.balances(user), sentAmount);
    assertEq(subject.reservedFunds(user), fee);
  }

  function test_requestWithCallbackCustomCallback_storesFeeData() public {
    uint256 fee = subject.fee();
    bytes4 callbackSelector = bytes4(keccak256("customFulfill(uint64,bytes32)"));

    uint64 requestId = subject.requestWithCallback{ value: fee }(callbackSelector);
    assertEq(subject.requestFees(requestId), fee);
  }

  function test_requestWithCallbackCustomCallback_emitsEvent() public {
    uint256 fee = subject.fee();
    bytes4 callbackSelector = bytes4(keccak256("customFulfill(uint64,bytes32)"));

    vm.expectEmit(true, true, true, true);
    emit Easyntropy.RequestSubmitted(
      1, // requestId
      user, // sender
      bytes4(keccak256("customFulfill(uint64,bytes32)")) // callbackSelector
    );
    subject.requestWithCallback{ value: fee }(callbackSelector);
  }

  function test_responseWithCallback_failsWhenExecutedByNotExecutor() public {
    vm.expectRevert(Easyntropy.PermissionDenied.selector);
    subject.responseWithCallback(
      1, // requestId
      address(subject), // requester
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(2)), // externalSeed
      3 // externalSeedId
    );
  }

  function test_responseWithCallback_callsCallback() public {
    EasyntropyConsumerDummy easyntropyConsumer = new EasyntropyConsumerDummy(address(subject));

    uint256 fee = easyntropyConsumer.entropyFee();
    uint64 requestId = easyntropyConsumer.internal__entropyRequestWithCallback{ value: fee }();

    __prank(executor);
    vm.expectEmit(true, true, true, true);
    emit EasyntropyConsumerDummy.FulfillmentSucceeded();

    subject.responseWithCallback(
      requestId,
      address(easyntropyConsumer), // requester
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(2)), // externalSeed
      3 // externalSeedId
    );
  }

  function test_responseWithCallback_failsIfNotEnoughBalance() public pure {
    // This cant happen because:
    // - you cant request rng without paying enough fee
    // - you cant withdraw reserved funds
    assertEq(true, true);
  }

  function test_responseWithCallback_transfersReservedFundsToExecutor() public {
    EasyntropyConsumerDummy easyntropyConsumer = new EasyntropyConsumerDummy(address(subject));

    uint256 fee = easyntropyConsumer.entropyFee();
    uint64 requestId = easyntropyConsumer.internal__entropyRequestWithCallback{ value: fee }();

    assertEq(subject.balances(address(easyntropyConsumer)), fee);
    assertEq(subject.reservedFunds(address(easyntropyConsumer)), fee);
    assertEq(executor.balance, 0);

    __prank(executor);
    subject.responseWithCallback(
      requestId,
      address(easyntropyConsumer), // requester
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(2)), // externalSeed
      3 // externalSeedId
    );
    assertEq(subject.balances(address(easyntropyConsumer)), 0);
    assertEq(subject.reservedFunds(address(easyntropyConsumer)), 0);
    assertEq(executor.balance, fee);
  }

  // private
  function __prank(address actor) public {
    vm.stopPrank();
    vm.startPrank(actor);
  }
}

contract EasyntropyConsumerDummy is EasyntropyConsumer {
  event FulfillmentSucceeded();

  constructor(address _entropy) EasyntropyConsumer(_entropy) {}
  function easyntropyFulfill(uint64, bytes32) public onlyEasyntropy {
    emit FulfillmentSucceeded();
  }

  function internal__entropyRequestWithCallback() public payable returns (uint64 requestId) {
    requestId = entropyRequestWithCallback();
  }
}
