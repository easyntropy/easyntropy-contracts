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

  function test_constructor_setsInitialBaseFee() public view {
    assertEq(subject.baseFee(), 1 wei);
  }

  function test_constructor_setsOwner() public view {
    assertEq(subject.owner(), owner);
  }

  function test_setBaseFee_setsBaseFee() public {
    __prank(owner);

    subject.setBaseFee(10 wei);
    assertEq(subject.baseFee(), 10 wei);
  }

  function test_setBaseFee_emitsBaseFeeSetEvent() public {
    __prank(owner);
    uint256 fee = 5 wei;

    vm.expectEmit(true, true, true, true);
    emit Easyntropy.BaseFeeSet(fee);
    subject.setBaseFee(fee);
  }

  function test_setBaseFee_failsWhenExecutedByNotOwner() public {
    vm.expectRevert(Easyntropy.PermissionDenied.selector);
    subject.setBaseFee(10 wei);
  }

  function test_setOwner_changesOwner() public {
    __prank(owner);

    address newOwner = makeAddr("newOwner");
    subject.setOwner(newOwner);
    assertEq(subject.owner(), newOwner);
  }

  function test_setOwner_emitsOwnerChangedEvent() public {
    __prank(owner);
    address newOwner = makeAddr("newOwner");

    vm.expectEmit(true, true, true, true);
    emit Easyntropy.OwnerSet(newOwner);
    subject.setOwner(newOwner);
  }

  function test_setOwner_failsWhenExecutedByNotOwner() public {
    address newOwner = makeAddr("newOwner");

    vm.expectRevert(Easyntropy.PermissionDenied.selector);
    subject.setOwner(newOwner);
  }

  function test_addExecutor_addsExecutor() public {
    __prank(owner);

    address newExecutor = makeAddr("newExecutor");
    subject.addExecutor(newExecutor);
    assertTrue(subject.executors(newExecutor));
  }

  function test_addExecutor_emitsExecutorAddedEvent() public {
    __prank(owner);
    address newExecutor = makeAddr("newExecutor");

    vm.expectEmit(true, true, true, true);
    emit Easyntropy.ExecutorAdded(newExecutor);
    subject.addExecutor(newExecutor);
  }

  function test_addExecutor_failsWhenExecutedByNotOwner() public {
    address newExecutor = makeAddr("newExecutor");

    vm.expectRevert(Easyntropy.PermissionDenied.selector);
    subject.addExecutor(newExecutor);
  }

  function test_removeExecutor_removesExecutor() public {
    __prank(owner);

    subject.removeExecutor(executor);
    assertFalse(subject.executors(executor));
  }

  function test_removeExecutor_emitsExecutorRemovedEvent() public {
    __prank(owner);

    vm.expectEmit(true, true, true, true);
    emit Easyntropy.ExecutorRemoved(executor);
    subject.removeExecutor(executor);
  }

  function test_removeExecutor_failsWhenExecutedByNotOwner() public {
    vm.expectRevert(Easyntropy.PermissionDenied.selector);
    subject.removeExecutor(executor);
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

  function test_withdraw_emitsFundsWithdrawnEvent() public {
    subject.deposit{ value: 10 wei }();

    vm.expectEmit(true, true, true, true);
    emit Easyntropy.FundsWithdrawn(user, 5 wei);
    subject.withdraw(5 wei);
  }

  function test_withdraw_releasesAndWithdrawsAlsoReservedFunds() public {
    subject.deposit{ value: 1 wei }();
    subject.requestWithCallback();

    assertEq(user.balance, 999999999999999999 wei);
    assertEq(subject.balances(user), 1 wei);
    assertEq(subject.reservedFunds(user), 1 wei);

    vm.expectRevert(Easyntropy.NotEnoughEth.selector);
    subject.withdraw(1 wei);

    vm.roll(block.number + subject.RELEASE_FUNDS_AFTER_BLOCKS() + 1);
    subject.withdraw(1 wei);

    assertEq(user.balance, 1 ether);
    assertEq(subject.balances(user), 0 wei);
    assertEq(subject.reservedFunds(user), 0 wei);
  }

  function test_withdraw_failsWhenNoFunds() public {
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

  function test_requestWithCallback_setLastResponseBlockNrForInitialRequest() public {
    EasyntropyConsumerWrapperExposingInternalMethods easyntropyConsumer = new EasyntropyConsumerWrapperExposingInternalMethods(
      address(subject)
    );

    uint256 fee = easyntropyConsumer.easyntropyFee();

    uint256 oldBlockNumber = block.number;

    // First request will set the lastResponseBlockNr to the current block number
    assertEq(subject.lastResponses(address(easyntropyConsumer)), 0);
    easyntropyConsumer.internal__easyntropyRequestWithCallback{ value: fee }();
    assertEq(subject.lastResponses(address(easyntropyConsumer)), oldBlockNumber);

    vm.roll(block.number + 10);

    // Second request wont modify the lastResponseBlockNr
    assertEq(subject.lastResponses(address(easyntropyConsumer)), oldBlockNumber);
    easyntropyConsumer.internal__easyntropyRequestWithCallback{ value: fee }();
    assertEq(subject.lastResponses(address(easyntropyConsumer)), oldBlockNumber);
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

  function test_requestWithCallbackCustomCallback_setLastResponseBlockNrForInitialRequest() public {
    EasyntropyConsumerWrapperExposingInternalMethods easyntropyConsumer = new EasyntropyConsumerWrapperExposingInternalMethods(
      address(subject)
    );

    uint256 fee = easyntropyConsumer.easyntropyFee();
    bytes4 callbackSelector = bytes4(keccak256("customFulfill(uint64,bytes32)"));

    uint256 oldBlockNumber = block.number;

    // First request will set the lastResponseBlockNr to the current block number
    assertEq(subject.lastResponses(address(easyntropyConsumer)), 0);
    easyntropyConsumer.internal__easyntropyRequestWithCallback{ value: fee }(callbackSelector);
    assertEq(subject.lastResponses(address(easyntropyConsumer)), oldBlockNumber);

    vm.roll(block.number + 10);

    // Second request wont modify the lastResponseBlockNr
    assertEq(subject.lastResponses(address(easyntropyConsumer)), oldBlockNumber);
    easyntropyConsumer.internal__easyntropyRequestWithCallback{ value: fee }(callbackSelector);
    assertEq(subject.lastResponses(address(easyntropyConsumer)), oldBlockNumber);
  }

  function test_responseWithCallback_failsWhenExecutedByNotExecutor() public {
    vm.expectRevert(Easyntropy.PermissionDenied.selector);
    subject.responseWithCallback(
      1, // requestId
      address(subject), // requester
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(2)) // seed
    );
  }

  function test_responseWithCallback_failsIfNotEnoughBalance() public pure {
    // This cant happen because:
    // - you cant request rng without paying enough fee
    // - you cant withdraw reserved funds
    assertEq(true, true);
  }

  function test_responseWithCallback_callsCallback() public {
    EasyntropyConsumerWrapperExposingInternalMethods easyntropyConsumer = new EasyntropyConsumerWrapperExposingInternalMethods(
      address(subject)
    );

    uint256 fee = easyntropyConsumer.easyntropyFee();
    uint64 requestId = easyntropyConsumer.internal__easyntropyRequestWithCallback{ value: fee }();

    __prank(executor);
    vm.expectEmit(true, true, true, true);
    emit EasyntropyConsumerWrapperExposingInternalMethods.FulfillmentSucceeded();

    subject.responseWithCallback(
      requestId,
      address(easyntropyConsumer), // requester
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(2)) // seed
    );
  }

  function test_responseWithCallback_storesBlockNumber() public {
    EasyntropyConsumerWrapperExposingInternalMethods easyntropyConsumer = new EasyntropyConsumerWrapperExposingInternalMethods(
      address(subject)
    );

    uint256 fee = easyntropyConsumer.easyntropyFee();

    assertEq(subject.lastResponses(address(easyntropyConsumer)), 0);
    uint64 requestId = easyntropyConsumer.internal__easyntropyRequestWithCallback{ value: fee }();
    assertEq(subject.lastResponses(address(easyntropyConsumer)), block.number);

    vm.roll(block.number + 10);

    __prank(executor);
    subject.responseWithCallback(
      requestId,
      address(easyntropyConsumer), // requester
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(2)) // seed
    );
    assertEq(subject.lastResponses(address(easyntropyConsumer)), block.number);
  }

  function test_responseWithCallback_transfersReservedFundsToExecutor() public {
    EasyntropyConsumerWrapperExposingInternalMethods easyntropyConsumer = new EasyntropyConsumerWrapperExposingInternalMethods(
      address(subject)
    );

    uint256 fee = easyntropyConsumer.easyntropyFee();
    uint64 requestId = easyntropyConsumer.internal__easyntropyRequestWithCallback{ value: fee }();

    assertEq(subject.balances(address(easyntropyConsumer)), fee);
    assertEq(subject.reservedFunds(address(easyntropyConsumer)), fee);
    assertEq(executor.balance, 0);

    __prank(executor);
    subject.responseWithCallback(
      requestId,
      address(easyntropyConsumer), // requester
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(2)) // seed
    );
    assertEq(subject.balances(address(easyntropyConsumer)), 0);
    assertEq(subject.reservedFunds(address(easyntropyConsumer)), 0);
    assertEq(executor.balance, fee);
  }

  function test_reservedFundsWaitingPeriod_returnsRemainingBlocksWithResponseCase() public {
    EasyntropyConsumerWrapperExposingInternalMethods easyntropyConsumer = new EasyntropyConsumerWrapperExposingInternalMethods(
      address(subject)
    );

    uint256 fee = easyntropyConsumer.easyntropyFee();
    uint64 requestId = easyntropyConsumer.internal__easyntropyRequestWithCallback{ value: fee }();

    vm.roll(1000);
    __prank(executor);
    subject.responseWithCallback(
      requestId,
      address(easyntropyConsumer), // requester
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(2)) // seed
    );
    assertEq(subject.lastResponses(address(easyntropyConsumer)), 1000);

    vm.roll(2000);
    assertEq(subject.reservedFundsWaitingPeriod(address(easyntropyConsumer)), subject.RELEASE_FUNDS_AFTER_BLOCKS() - 1000);
  }

  function test_reservedFundsWaitingPeriod_returnsRemainingBlocksNoResponseCase() public {
    uint256 fee = subject.fee();

    vm.roll(1000);
    subject.requestWithCallback{ value: fee }();
    assertEq(subject.lastResponses(user), 1000);

    vm.roll(2000);
    assertEq(subject.reservedFundsWaitingPeriod(user), subject.RELEASE_FUNDS_AFTER_BLOCKS() - 1000);
  }

  function test_reservedFundsWaitingPeriod_returnsZeroAfterPeriod() public {
    uint256 fee = subject.fee();

    vm.roll(1000);
    subject.requestWithCallback{ value: fee }();
    vm.roll(1000 + subject.RELEASE_FUNDS_AFTER_BLOCKS());
    assertEq(subject.reservedFundsWaitingPeriod(user), 0);

    vm.roll(10 * subject.RELEASE_FUNDS_AFTER_BLOCKS());
    assertEq(subject.reservedFundsWaitingPeriod(user), 0);
  }

  function test_setCustomFee_setsCustomFee() public {
    __prank(owner);

    subject.setCustomFee(user, 10 wei);
    assertEq(subject.customFees(user), 10 wei);
  }

  function test_setCustomFee_emitsEvent() public {
    __prank(owner);

    vm.expectEmit(true, true, true, true);
    emit Easyntropy.CustomFeeSet(user, 10 wei);
    subject.setCustomFee(user, 10 wei);
  }

  function test_setCustomFee_failsWhenExecutedByNotOwner() public {
    vm.expectRevert(Easyntropy.PermissionDenied.selector);
    subject.setCustomFee(user, 10 wei);
  }

  function test_removeCustomFee_removesCustomFee() public {
    __prank(owner);

    subject.setCustomFee(user, 10 wei);
    assertEq(subject.customFees(user), 10 wei);

    subject.removeCustomFee(user);
    assertEq(subject.customFees(user), 0);
  }

  function test_removeCustomFee_emitsEvent() public {
    __prank(owner);

    vm.expectEmit(true, true, true, true);
    emit Easyntropy.CustomFeeRemoved(user);
    subject.removeCustomFee(user);
  }

  function test_removeCustomFee_failsWhenExecutedByNotOwner() public {
    vm.expectRevert(Easyntropy.PermissionDenied.selector);
    subject.removeCustomFee(user);
  }

  function test_fee_returnsCustomFeeWhenSet() public {
    __prank(owner);
    subject.setCustomFee(user, 10 wei);

    __prank(user);
    assertEq(subject.fee(), 10 wei);
  }

  function test_fee_returnsBaseFeeWhenNoCustomFeeWasSet() public view {
    assertEq(subject.customFees(user), 0);
    assertEq(subject.baseFee(), subject.fee());
  }

  function test_fee_returnsZeroWhenCustomFeeIsSetToMax() public {
    __prank(owner);
    subject.setCustomFee(user, type(uint256).max);

    __prank(user);
    assertEq(subject.fee(), 0);
  }

  function test_fee_returnsBaseFeeAfterRemovingCustomFee() public {
    __prank(owner);
    subject.setCustomFee(user, 10 wei);
    subject.removeCustomFee(user);

    __prank(user);
    assertEq(subject.fee(), 1 wei);
  }

  // private
  function __prank(address actor) public {
    vm.stopPrank();
    vm.startPrank(actor);
  }
}

contract EasyntropyConsumerWrapperExposingInternalMethods is EasyntropyConsumer {
  event FulfillmentSucceeded();

  constructor(address _entropy) EasyntropyConsumer(_entropy) {}
  function easyntropyFulfill(uint64, bytes32) public onlyEasyntropy {
    emit FulfillmentSucceeded();
  }

  function internal__easyntropyRequestWithCallback() public payable returns (uint64 requestId) {
    requestId = easyntropyRequestWithCallback();
  }

  function internal__easyntropyRequestWithCallback(bytes4 callbackSelector) public payable returns (uint64 requestId) {
    requestId = easyntropyRequestWithCallback(callbackSelector);
  }
}
