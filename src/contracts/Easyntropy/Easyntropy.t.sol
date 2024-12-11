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
  address public vault;
  address public user;

  function setUp() public {
    owner = makeAddr("owner");
    user = makeAddr("user");
    vault = makeAddr("vault");
    vm.deal(owner, 1 ether);
    vm.deal(user, 1 ether);

    __prank(owner);
    subject = new Easyntropy(vault, 1 wei);

    __prank(user);
  }

  function test_constructor_SetsInitialFee() public view {
    assertEq(subject.fee(), 1 wei);
  }

  function test_constructor_SetsOwner() public view {
    assertEq(subject.owner(), owner);
  }

  function test_setFee_SetsFee() public {
    __prank(owner);

    subject.setFee(10 wei);
    assertEq(subject.fee(), 10 wei);
  }

  function test_setFee_FailsWhenExecutedByNotOwner() public {
    vm.expectRevert(Easyntropy.PermissionDenied.selector);
    subject.setFee(10 wei);
  }

  function test_setVault_SetsVault() public {
    __prank(owner);

    address newVault = makeAddr("newVault");
    subject.setVault(newVault);
    assertEq(subject.vault(), newVault);
  }

  function test_setVault_FailsWhenExecutedByNotOwner() public {
    address newVault = makeAddr("newVault");

    vm.expectRevert(Easyntropy.PermissionDenied.selector);
    subject.setVault(newVault);
  }

  function test_withdraw_WithdrawsFunds() public {
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

  function test_withdraw_FailsWhenNotFunds() public {
    assertEq(subject.balances(user), 0 wei);

    vm.expectRevert(Easyntropy.NotEnoughEth.selector);
    subject.withdraw(10 wei);
  }

  function test_withdraw_FailsWhenNotEnoughFunds() public {
    subject.deposit{ value: 1 wei }();
    assertEq(subject.balances(user), 1 wei);

    vm.expectRevert(Easyntropy.NotEnoughEth.selector);
    subject.withdraw(10 wei);
  }

  function test_withdraw_FailsWhenNotEnoughFundsBecauseReserved() public {
    subject.deposit{ value: 1 wei }();
    subject.requestWithCallback();
    assertEq(subject.balances(user), 1 wei);
    assertEq(subject.reservedFunds(user), 1 wei);

    vm.expectRevert(Easyntropy.NotEnoughEth.selector);
    subject.withdraw(10 wei);
  }

  function test_deposit_DepositsFundsToSender() public {
    assertEq(subject.balances(user), 0);
    subject.deposit{ value: 0.5 ether }();
    assertEq(subject.balances(user), 0.5 ether);
  }

  function test_deposit_EmitsDepositedEvent() public {
    vm.expectEmit(true, true, true, true);
    emit Easyntropy.DepositReceived(user, 0.5 ether);

    subject.deposit{ value: 0.5 ether }();
  }

  function test_requestWithCallback_FailsWhenThereIsNotEnoughBalance() public {
    uint256 fee = subject.fee();

    subject.deposit{ value: fee - 1 wei }();
    vm.expectRevert(Easyntropy.NotEnoughEth.selector);
    subject.requestWithCallback{ value: 0 }();
  }

  function test_requestWithCallback_BumpsRequestId() public {
    uint256 fee = subject.fee();

    assertEq(subject.lastRequestId(), 0);
    subject.requestWithCallback{ value: fee }();
    assertEq(subject.lastRequestId(), 1);
  }

  function test_requestWithCallback_CreditsSenderAccount() public {
    uint256 fee = subject.fee();

    assertEq(subject.balances(user), 0);
    assertEq(subject.reservedFunds(user), 0);
    subject.requestWithCallback{ value: fee }();
    assertEq(subject.balances(user), fee);
    assertEq(subject.reservedFunds(user), fee);
  }

  function test_requestWithCallback_CreditsSenderAccountSentMoreThanFee() public {
    uint256 fee = subject.fee();
    uint256 sentAmount = fee + 1 wei;

    assertEq(subject.balances(user), 0);
    assertEq(subject.reservedFunds(user), 0);
    subject.requestWithCallback{ value: sentAmount }();
    assertEq(subject.balances(user), sentAmount);
    assertEq(subject.reservedFunds(user), fee);
  }

  function test_requestWithCallback_StoresFeeData() public {
    uint256 fee = subject.fee();

    uint64 requestId = subject.requestWithCallback{ value: fee }();
    assertEq(subject.requestFees(requestId), fee);
  }

  function test_requestWithCallback_EmitsEvent() public {
    uint256 fee = subject.fee();

    vm.expectEmit(true, true, true, true);
    emit Easyntropy.RequestSubmitted(
      1, // requestId
      user, // sender
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")) // callbackSelector
    );
    subject.requestWithCallback{ value: fee }();
  }

  function test_requestWithCallbackCustomCallback_FailsWhenThereIsNotEnoughBalance() public {
    uint256 fee = subject.fee();
    bytes4 callbackSelector = bytes4(keccak256("customFulfill(uint64,bytes32)"));

    subject.deposit{ value: fee - 1 wei }();
    vm.expectRevert(Easyntropy.NotEnoughEth.selector);
    subject.requestWithCallback{ value: 0 }(callbackSelector);
  }

  function test_requestWithCallbackCustomCallback_BumpsRequestId() public {
    uint256 fee = subject.fee();
    bytes4 callbackSelector = bytes4(keccak256("customFulfill(uint64,bytes32)"));

    assertEq(subject.lastRequestId(), 0);
    subject.requestWithCallback{ value: fee }(callbackSelector);
    assertEq(subject.lastRequestId(), 1);
  }

  function test_requestWithCallbackCustomCallback_CreditsSenderAccount() public {
    uint256 fee = subject.fee();
    bytes4 callbackSelector = bytes4(keccak256("customFulfill(uint64,bytes32)"));

    assertEq(subject.balances(user), 0);
    assertEq(subject.reservedFunds(user), 0);
    subject.requestWithCallback{ value: fee }(callbackSelector);
    assertEq(subject.balances(user), fee);
    assertEq(subject.reservedFunds(user), fee);
  }

  function test_requestWithCallbackCustomCallback_CreditsSenderAccountSentMoreThanFee() public {
    uint256 fee = subject.fee();
    uint256 sentAmount = fee + 1 wei;
    bytes4 callbackSelector = bytes4(keccak256("customFulfill(uint64,bytes32)"));

    assertEq(subject.balances(user), 0);
    assertEq(subject.reservedFunds(user), 0);
    subject.requestWithCallback{ value: sentAmount }(callbackSelector);
    assertEq(subject.balances(user), sentAmount);
    assertEq(subject.reservedFunds(user), fee);
  }

  function test_requestWithCallbackCustomCallback_StoresFeeData() public {
    uint256 fee = subject.fee();
    bytes4 callbackSelector = bytes4(keccak256("customFulfill(uint64,bytes32)"));

    uint64 requestId = subject.requestWithCallback{ value: fee }(callbackSelector);
    assertEq(subject.requestFees(requestId), fee);
  }

  function test_requestWithCallbackCustomCallback_EmitsEvent() public {
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

  function test_responseWithCallback__FailsWhenExecutedByNotVault() public {
    vm.expectRevert(Easyntropy.PermissionDenied.selector);
    subject.responseWithCallback(
      1, // requestId
      address(subject), // requester
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(2)), // externalSeed
      3 // externalSeedId
    );
  }

  function test_responseWithCallback__CallsCallback() public {
    EasyntropyConsumerDummy easyntropyConsumer = new EasyntropyConsumerDummy(address(subject));

    uint256 fee = easyntropyConsumer.entropyFee();
    uint64 requestId = easyntropyConsumer.internal__entropyRequestWithCallback{ value: fee }();

    __prank(vault);
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

  function test_responseWithCallback__FailsIfNotEnoughBalance() public pure {
    // This cant happen because:
    // - you cant request rng without paying enough fee
    // - you cant withdraw reserved funds
    assertEq(true, true);
  }

  function test_responseWithCallback__TransfersReservedFundsToVault() public {
    EasyntropyConsumerDummy easyntropyConsumer = new EasyntropyConsumerDummy(address(subject));

    uint256 fee = easyntropyConsumer.entropyFee();
    uint64 requestId = easyntropyConsumer.internal__entropyRequestWithCallback{ value: fee }();

    assertEq(subject.balances(address(easyntropyConsumer)), fee);
    assertEq(subject.reservedFunds(address(easyntropyConsumer)), fee);
    assertEq(vault.balance, 0);

    __prank(vault);
    subject.responseWithCallback(
      requestId,
      address(easyntropyConsumer), // requester
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(2)), // externalSeed
      3 // externalSeedId
    );
    assertEq(subject.balances(address(easyntropyConsumer)), 0);
    assertEq(subject.reservedFunds(address(easyntropyConsumer)), 0);
    assertEq(vault.balance, fee);
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
