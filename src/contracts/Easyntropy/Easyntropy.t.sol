/* solhint-disable func-name-mixedcase, gas-strict-inequalities */
/* solhint-enable foundry-test-functions */

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { Easyntropy } from "./Easyntropy.sol";

contract EasyntropyTest is Test {
  Easyntropy private subject;
  address public owner;
  address public user;

  function setUp() public {
    owner = makeAddr("owner");
    user = makeAddr("user");
    vm.deal(owner, 1 ether);
    vm.deal(user, 1 ether);

    __prank(owner);
    subject = new Easyntropy(1 wei);

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

    assertEq(subject.requestId(), 0);
    subject.requestWithCallback{ value: fee }();
    assertEq(subject.requestId(), 1);
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

    assertEq(subject.requestId(), 0);
    subject.requestWithCallback{ value: fee }(callbackSelector);
    assertEq(subject.requestId(), 1);
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

  // private
  function __prank(address actor) public {
    vm.stopPrank();
    vm.startPrank(actor);
  }
}
