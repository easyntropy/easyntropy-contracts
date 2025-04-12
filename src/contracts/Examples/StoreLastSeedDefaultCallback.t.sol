/* solhint-disable func-name-mixedcase, gas-strict-inequalities */
/* solhint-enable foundry-test-functions */

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { Easyntropy } from "../Easyntropy/Easyntropy.sol";
import { StoreLastSeedDefaultCallback } from "./StoreLastSeedDefaultCallback.sol";

contract StoreLastSeedDefaultCallbackTest is Test {
  Easyntropy private easyntropy;
  StoreLastSeedDefaultCallback private subject;
  address public user;
  address public executor;

  function setUp() public {
    user = makeAddr("user");
    executor = makeAddr("executor");
    vm.deal(user, 1 ether);
    vm.startPrank(user);

    easyntropy = new Easyntropy(executor, 1 wei);
    subject = new StoreLastSeedDefaultCallback(address(easyntropy));
  }

  function test_constructor_setsEntropyAddresses() public view {
    assertEq(address(subject.entropy()), address(easyntropy));
  }

  function test_easyntropyFee_returnsExpectedFeeFuzzy(uint256 fee) public {
    easyntropy.setFee(fee);
    assertEq(subject.easyntropyFee(), easyntropy.fee());
  }

  function test_requestRandomValue_failsIfNotEnoughMoneyIsSent() public {
    vm.expectRevert(StoreLastSeedDefaultCallback.NotEnoughEth.selector);
    subject.requestRandomValue{ value: 0 }();
  }

  function test_requestRandomValue_emitsRandomValueRequestedEvent() public {
    vm.expectEmit(true, true, false, false);
    emit StoreLastSeedDefaultCallback.RandomValueRequested(1);
    subject.requestRandomValue{ value: subject.easyntropyFee() }();
  }

  function test_requestRandomValue_callsEasyntropy() public {
    vm.expectEmit(true, true, true, true);
    emit Easyntropy.RequestSubmitted(
      1, // requestId
      address(subject), // sender
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")) // callbackSelector
    );
    subject.requestRandomValue{ value: subject.easyntropyFee() }();
  }

  function test_easyntropyFullfill_failsWhenCalledByNonOracle() public {
    vm.expectRevert(); // revert due to permissions, only executor can call this function
    subject.easyntropyFulfill(
      1, // requestId
      bytes32(uint256(2)) // externalSeed
    );
  }

  function test_easyntropyFullfill_emitsRandomValueObtainedEvent() public {
    uint64 requestId = subject.requestRandomValue{ value: subject.easyntropyFee() }();

    vm.startPrank(executor);

    vm.expectEmit(true, true, false, false);
    emit StoreLastSeedDefaultCallback.RandomValueObtained(requestId, bytes32(uint256(2)));

    easyntropy.responseWithCallback(
      requestId,
      address(subject), // requester
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(2)), // externalSeed
      3 // externalSeedId
    );
  }

  function test_easyntropyFullfill_assignLastSeed() public {
    uint64 requestId = subject.requestRandomValue{ value: subject.easyntropyFee() }();

    bytes32 fakeSeed = bytes32(uint256(2));
    vm.startPrank(executor);
    easyntropy.responseWithCallback(
      requestId,
      address(subject), // requester
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")), // callbackSelector
      fakeSeed, // externalSeed
      3 // externalSeedId
    );
    assertEq(subject.latestSeed(), fakeSeed);
  }
}
