/* solhint-disable func-name-mixedcase, gas-strict-inequalities */
/* solhint-enable foundry-test-functions */

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { Easyntropy } from "../Easyntropy/Easyntropy.sol";
import { StoreLastSeedCustomCallback } from "./StoreLastSeedCustomCallback.sol";

contract StoreLastSeedCustomCallbackTest is Test {
  Easyntropy private easyntropy;
  StoreLastSeedCustomCallback private subject;
  address public user;
  address public executor;

  function setUp() public {
    user = makeAddr("user");
    executor = makeAddr("executor");
    vm.deal(user, 1 ether);
    vm.startPrank(user);

    easyntropy = new Easyntropy(executor, 1 wei);
    subject = new StoreLastSeedCustomCallback(address(easyntropy));
  }

  function test_constructor_setsEasyntropyAddresses() public view {
    assertEq(address(subject.easyntropy()), address(easyntropy));
  }

  function test_easyntropyFee_returnsExpectedFeeFuzzy(uint256 fee) public {
    easyntropy.setBaseFee(fee);
    assertEq(subject.easyntropyFee(), easyntropy.fee());
  }

  function test_requestRandomValueCustomCallback_failsIfNotEnoughMoneyIsSent() public {
    vm.expectRevert(StoreLastSeedCustomCallback.NotEnoughEth.selector);
    subject.requestRandomValueCustomCallback{ value: 0 }();
  }

  function test_requestRandomValueCustomCallback_emitsRandomValueRequestedEvent() public {
    vm.expectEmit(true, true, false, false);
    emit StoreLastSeedCustomCallback.RandomValueRequested(1);
    subject.requestRandomValueCustomCallback{ value: subject.easyntropyFee() }();
  }

  function test_requestRandomValueCustomCallback_callsEasyntropy() public {
    vm.expectEmit(true, true, true, true);
    emit Easyntropy.RequestSubmitted(
      1, // requestId
      address(subject), // sender
      bytes4(keccak256("customFulfill(uint64,bytes32)")) // callbackSelector
    );
    subject.requestRandomValueCustomCallback{ value: subject.easyntropyFee() }();
  }

  function test_easyntropyFullfill_emitsRandomValueObtainedEvent() public {
    uint64 requestId = subject.requestRandomValueCustomCallback{ value: subject.easyntropyFee() }();

    vm.startPrank(executor);

    vm.expectEmit(true, true, false, false);
    emit StoreLastSeedCustomCallback.RandomValueObtained(requestId, bytes32(uint256(2)));
    easyntropy.responseWithCallback(
      requestId,
      address(subject), // requester
      bytes4(keccak256("customFulfill(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(2)), // externalSeed
      3 // externalSeedId
    );
  }

  function test_easyntropyFullfill_assignLastSeed() public {
    uint64 requestId = subject.requestRandomValueCustomCallback{ value: subject.easyntropyFee() }();

    vm.startPrank(executor);
    bytes32 fakeSeed = bytes32(uint256(2));
    easyntropy.responseWithCallback(
      requestId,
      address(subject), // requester
      bytes4(keccak256("customFulfill(uint64,bytes32)")), // callbackSelector
      fakeSeed, // externalSeed
      3 // externalSeedId
    );
    assertEq(subject.latestSeed(), fakeSeed);
  }
}
