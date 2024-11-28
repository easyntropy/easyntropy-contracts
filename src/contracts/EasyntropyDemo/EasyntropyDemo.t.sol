/* solhint-disable func-name-mixedcase, gas-strict-inequalities */
/* solhint-enable foundry-test-functions */

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { Easyntropy } from "../Easyntropy/Easyntropy.sol";
import { EasyntropyDemo } from "./EasyntropyDemo.sol";

contract EasyntropyDemoTest is Test {
  Easyntropy private easyntropy;
  EasyntropyDemo private subject;
  address public user;
  address public vault;

  function setUp() public {
    user = makeAddr("user");
    vault = makeAddr("vault");
    vm.deal(user, 1 ether);
    vm.startPrank(user);

    easyntropy = new Easyntropy(vault, 1 wei);
    subject = new EasyntropyDemo(address(easyntropy));
  }

  function test_constructor_SetsEntropyAddresses() public view {
    assertEq(address(subject.entropy()), address(easyntropy));
  }

  function test_entropyFee_ReturnsExpectedFeeFuzzy(uint256 fee) public {
    easyntropy.setFee(fee);
    assertEq(subject.entropyFee(), easyntropy.fee());
  }

  function test_requestRandomValue_FailsIfNotEnoughMoneyIsSent() public {
    vm.expectRevert(EasyntropyDemo.NotEnoughEth.selector);
    subject.requestRandomValue{ value: 0 }();
  }

  function test_requestRandomValue_EmitsRandomValueRequestedEvent() public {
    uint256 fee = subject.entropyFee();

    vm.expectEmit(true, true, false, false);
    emit EasyntropyDemo.RandomValueRequested(1);
    subject.requestRandomValue{ value: fee }();
  }

  function test_requestRandomValue_AddsEntryToPendingRequests() public {
    uint256 fee = subject.entropyFee();

    uint64 sequenceNumber = subject.requestRandomValue{ value: fee }();

    bool pendingRequest = subject.pendingRequests(sequenceNumber);
    assertEq(pendingRequest, true);
  }

  function test_requestRandomValue_CallsEasyntropy() public {
    uint256 fee = subject.entropyFee();

    vm.expectEmit(true, true, true, true);
    emit Easyntropy.RequestSubmitted(
      1, // sequenceNumber
      address(subject), // sender
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")) // callbackSelector
    );
    subject.requestRandomValue{ value: fee }();
  }

  function test_requestRandomValueCustomCallback_FailsIfNotEnoughMoneyIsSent() public {
    vm.expectRevert(EasyntropyDemo.NotEnoughEth.selector);
    subject.requestRandomValueCustomCallback{ value: 0 }();
  }

  function test_requestRandomValueCustomCallback_EmitsRandomValueRequestedEvent() public {
    uint256 fee = subject.entropyFee();

    vm.expectEmit(true, true, false, false);
    emit EasyntropyDemo.RandomValueRequested(1);
    subject.requestRandomValueCustomCallback{ value: fee }();
  }

  function test_requestRandomValueCustomCallback_AddsEntryToPendingRequests() public {
    uint256 fee = subject.entropyFee();

    uint64 sequenceNumber = subject.requestRandomValueCustomCallback{ value: fee }();

    bool pendingRequest = subject.pendingRequests(sequenceNumber);
    assertEq(pendingRequest, true);
  }

  function test_requestRandomValueCustomCallback_CallsEasyntropy() public {
    uint256 fee = subject.entropyFee();

    vm.expectEmit(true, true, true, true);
    emit Easyntropy.RequestSubmitted(
      1, // sequenceNumber
      address(subject), // sender
      bytes4(keccak256("customFulfill(uint64,bytes32)")) // callbackSelector
    );
    subject.requestRandomValueCustomCallback{ value: fee }();
  }
}
