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
  address public executor;

  function setUp() public {
    user = makeAddr("user");
    executor = makeAddr("executor");
    vm.deal(user, 1 ether);
    vm.startPrank(user);

    easyntropy = new Easyntropy(executor, 1 wei);
    subject = new EasyntropyDemo(address(easyntropy));
  }

  function test_constructor_setsEntropyAddresses() public view {
    assertEq(address(subject.entropy()), address(easyntropy));
  }

  function test_entropyFee_returnsExpectedFeeFuzzy(uint256 fee) public {
    easyntropy.setFee(fee);
    assertEq(subject.entropyFee(), easyntropy.fee());
  }

  function test_requestRandomValue_failsIfNotEnoughMoneyIsSent() public {
    vm.expectRevert(EasyntropyDemo.NotEnoughEth.selector);
    subject.requestRandomValue{ value: 0 }();
  }

  function test_requestRandomValue_emitsRandomValueRequestedEvent() public {
    uint256 fee = subject.entropyFee();

    vm.expectEmit(true, true, false, false);
    emit EasyntropyDemo.RandomValueRequested(1);
    subject.requestRandomValue{ value: fee }();
  }

  function test_requestRandomValue_addsEntryToPendingRequests() public {
    uint256 fee = subject.entropyFee();

    uint64 requestId = subject.requestRandomValue{ value: fee }();

    bool pendingRequest = subject.pendingRequests(requestId);
    assertEq(pendingRequest, true);
  }

  function test_requestRandomValue_callsEasyntropy() public {
    uint256 fee = subject.entropyFee();

    vm.expectEmit(true, true, true, true);
    emit Easyntropy.RequestSubmitted(
      1, // requestId
      address(subject), // sender
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")) // callbackSelector
    );
    subject.requestRandomValue{ value: fee }();
  }

  function test_requestRandomValueCustomCallback_failsIfNotEnoughMoneyIsSent() public {
    vm.expectRevert(EasyntropyDemo.NotEnoughEth.selector);
    subject.requestRandomValueCustomCallback{ value: 0 }();
  }

  function test_requestRandomValueCustomCallback_emitsRandomValueRequestedEvent() public {
    uint256 fee = subject.entropyFee();

    vm.expectEmit(true, true, false, false);
    emit EasyntropyDemo.RandomValueRequested(1);
    subject.requestRandomValueCustomCallback{ value: fee }();
  }

  function test_requestRandomValueCustomCallback_addsEntryToPendingRequests() public {
    uint256 fee = subject.entropyFee();

    uint64 requestId = subject.requestRandomValueCustomCallback{ value: fee }();

    bool pendingRequest = subject.pendingRequests(requestId);
    assertEq(pendingRequest, true);
  }

  function test_requestRandomValueCustomCallback_callsEasyntropy() public {
    uint256 fee = subject.entropyFee();

    vm.expectEmit(true, true, true, true);
    emit Easyntropy.RequestSubmitted(
      1, // requestId
      address(subject), // sender
      bytes4(keccak256("customFulfill(uint64,bytes32)")) // callbackSelector
    );
    subject.requestRandomValueCustomCallback{ value: fee }();
  }
}
