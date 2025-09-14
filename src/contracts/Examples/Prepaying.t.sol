/* solhint-disable func-name-mixedcase, gas-strict-inequalities */
/* solhint-enable foundry-test-functions */

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { Easyntropy } from "../Easyntropy/Easyntropy.sol";
import { Prepaying } from "./Prepaying.sol";

contract PrepayingTest is Test {
  Easyntropy private easyntropy;
  Prepaying private subject;
  address public user;
  address public executor;

  function setUp() public {
    user = makeAddr("user");
    executor = makeAddr("executor");
    vm.deal(user, 1 ether);
    vm.startPrank(user);

    easyntropy = new Easyntropy(executor, 1 wei);
    subject = new Prepaying(address(easyntropy));
  }

  function test_constructor_setsEasyntropyAddresses() public view {
    assertEq(address(subject.easyntropy()), address(easyntropy));
  }

  function test_requestRandomValueWithoutPaying_callsEasyntropy() public {
    subject.easyntropyDeposit{ value: 1 ether }();

    vm.expectEmit(true, true, true, true);
    emit Easyntropy.RequestSubmitted(
      1, // requestId
      address(subject), // sender
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")) // callbackSelector
    );
    subject.requestRandomValueWithoutPaying();
  }

  function test_requestRandomValueWithoutPaying_assignLastSeed() public {
    subject.easyntropyDeposit{ value: 1 ether }();

    uint64 requestId = subject.requestRandomValueWithoutPaying();

    vm.startPrank(executor);
    bytes32 fakeSeed = bytes32(uint256(2));
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
