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

  function test_withdraw_WithdrawsMoney() public {
    __prank(owner);

    payable(subject).transfer(0.6 ether);
    assertEq(owner.balance, 0.4 ether);
    assertEq(address(subject).balance, 0.6 ether);

    subject.withdraw(0.6 ether);

    assertEq(owner.balance, 1 ether);
    assertEq(address(subject).balance, 0 ether);
  }

  function test_withdraw_FailsWhenExecutedByNotOwner() public {
    vm.expectRevert(Easyntropy.PermissionDenied.selector);
    subject.withdraw(0.6 ether);
  }

  function test_requestWithCallback_FailsWhenNotEnoughEthIsSent() public {
    vm.expectRevert(Easyntropy.NotEnoughEth.selector);
    subject.requestWithCallback{ value: 0 }();
  }

  function test_requestWithCallback_BumpsRequestId() public {
    uint256 fee = subject.fee();

    assertEq(subject.lastRequestId(), 0);
    subject.requestWithCallback{ value: fee }();
    assertEq(subject.lastRequestId(), 1);
  }

  function test_requestWithCallback_CreditsVaultAccount() public {
    uint256 fee = subject.fee();

    assertEq(vault.balance, 0);
    assertEq(address(subject).balance, 0);
    subject.requestWithCallback{ value: fee }();
    assertEq(address(subject).balance, 0);
    assertEq(vault.balance, fee);
  }

  function test_requestWithCallback_EmitsEvent() public {
    uint256 fee = subject.fee();

    vm.expectEmit(true, true, true, true);
    emit Easyntropy.RequestSubmitted(
      1, // sequenceNumber
      user, // sender
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")) // callbackSelector
    );
    subject.requestWithCallback{ value: fee }();
  }

  function test_requestWithCallbackCustomCallback_FailsWhenNotEnoughEthIsSent() public {
    bytes4 callbackSelector = bytes4(keccak256("customFulfill(uint64,bytes32)"));

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

  function test_requestWithCallbackCustomCallback_CreditsVaultAccount() public {
    uint256 fee = subject.fee();
    bytes4 callbackSelector = bytes4(keccak256("customFulfill(uint64,bytes32)"));

    assertEq(vault.balance, 0);
    assertEq(address(subject).balance, 0);
    subject.requestWithCallback{ value: fee }(callbackSelector);
    assertEq(address(subject).balance, 0);
    assertEq(vault.balance, fee);
  }

  function test_requestWithCallbackCustomCallback_EmitsEvent() public {
    uint256 fee = subject.fee();
    bytes4 callbackSelector = bytes4(keccak256("customFulfill(uint64,bytes32)"));

    vm.expectEmit(true, true, true, true);
    emit Easyntropy.RequestSubmitted(
      1, // sequenceNumber
      user, // sender
      bytes4(keccak256("customFulfill(uint64,bytes32)")) // callbackSelector
    );
    subject.requestWithCallback{ value: fee }(callbackSelector);
  }

  function test_responseWithCallback__FailsWhenExecutedByNotVault() public {
    vm.expectRevert(Easyntropy.PermissionDenied.selector);
    subject.responseWithCallback(
      1, // sequenceNumber
      address(subject), // requester
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(2)), // externalSeed
      3 // externalSeedId
    );
  }

  function test_responseWithCallback__CallsCallback() public {
    __prank(vault);
    EasyntropyConsumerDummy easyntropyConsumer = new EasyntropyConsumerDummy(address(subject));

    vm.expectEmit(true, true, true, true);
    emit EasyntropyConsumerDummy.FulfillmentSucceeded();

    subject.responseWithCallback(
      1, // sequenceNumber
      address(easyntropyConsumer), // requester
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(2)), // externalSeed
      3 // externalSeedId
    );
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
}
