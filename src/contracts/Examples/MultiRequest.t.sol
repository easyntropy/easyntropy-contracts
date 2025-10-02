/* solhint-disable func-name-mixedcase, gas-strict-inequalities */
/* solhint-enable foundry-test-functions */

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { Easyntropy } from "../Easyntropy/Easyntropy.sol";
import { MultiRequest } from "./MultiRequest.sol";

contract MultiRequestTest is Test {
  Easyntropy private easyntropy;
  MultiRequest private subject;
  address public user;
  address public executor;

  function setUp() public {
    user = makeAddr("user");
    executor = makeAddr("executor");
    vm.deal(user, 1 ether);
    vm.startPrank(user);

    easyntropy = new Easyntropy(executor, 1 wei);
    subject = new MultiRequest(address(easyntropy));
  }

  function test_constructor_setsEasyntropyAddresses() public view {
    assertEq(address(subject.easyntropy()), address(easyntropy));
  }

  function test_easyntropyFee_returnsExpectedFeeFuzzy(uint256 fee) public {
    easyntropy.setBaseFee(fee);
    assertEq(subject.easyntropyFee(), easyntropy.fee());
  }

  function test_calculateFee_returnsExpectedFee(uint256 count, uint256 fee) public {
    vm.assume(fee > 0 && count <= type(uint256).max / fee);
    easyntropy.setBaseFee(fee);
    uint256 expectedFee = count * fee;
    assertEq(subject.calculateFee(count), expectedFee);
  }

  function test_requestRandomValues_failsIfNotEnoughMoneyIsSent() public {
    vm.expectRevert(MultiRequest.NotEnoughEth.selector);
    subject.requestRandomValues{ value: 0 }(1);
  }

  function test_requestRandomValues_emitsRandomValueRequestedEvent() public {
    vm.expectEmit(true, true, false, false);
    emit MultiRequest.RandomValueRequested(1);
    subject.requestRandomValues{ value: subject.easyntropyFee() }(1);
  }

  function test_requestRandomValues_callsEasyntropy() public {
    vm.expectEmit(true, true, true, true);
    emit Easyntropy.RequestSubmitted(
      1, // requestId
      address(subject), // sender
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")) // callbackSelector
    );
    subject.requestRandomValues{ value: subject.easyntropyFee() }(1);
  }

  function test_requestRandomValues_multipleRequests() public {
    uint256 count = 3;
    uint256 totalFee = count * subject.easyntropyFee();
    subject.requestRandomValues{ value: totalFee }(count);

    // Check that currentCallId is incremented
    assertEq(subject.currentCallId(), count);

    // Check pending requests
    for (uint64 i = 1; i <= count; ++i) {
      uint256 callId = subject.pendingRequests(i);
      assertEq(callId, i);
    }
  }

  function test_easyntropyFulfill_failsWhenCalledByNonOracle() public {
    vm.expectRevert(); // revert due to permissions, only executor can call this function
    subject.easyntropyFulfill(
      1, // requestId
      bytes32(uint256(2)) // externalSeed
    );
  }

  function test_easyntropyFulfill_emitsRandomValueObtainedEvent() public {
    subject.requestRandomValues{ value: subject.easyntropyFee() }(1);

    vm.startPrank(executor);

    vm.expectEmit(true, true, false, false);
    emit MultiRequest.RandomValueObtained(1, bytes32(uint256(2)));

    easyntropy.responseWithCallback(
      1,
      address(subject), // requester
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(2)) // externalSeed
    );
  }

  function test_easyntropyFulfill_assignsSeed() public {
    subject.requestRandomValues{ value: subject.easyntropyFee() }(1);

    bytes32 fakeSeed = bytes32(uint256(42));
    vm.startPrank(executor);
    easyntropy.responseWithCallback(
      1,
      address(subject), // requester
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")), // callbackSelector
      fakeSeed // externalSeed
    );

    assertEq(subject.seeds(1), fakeSeed);
  }

  function test_easyntropyFulfill_cleansUpPendingRequest() public {
    subject.requestRandomValues{ value: subject.easyntropyFee() }(1);

    vm.startPrank(executor);
    easyntropy.responseWithCallback(
      1,
      address(subject), // requester
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(1)) // externalSeed
    );

    uint256 callId = subject.pendingRequests(1);
    assertEq(callId, 0);
  }
}
