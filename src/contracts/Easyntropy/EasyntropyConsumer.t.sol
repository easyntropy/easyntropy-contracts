/* solhint-disable func-name-mixedcase, gas-strict-inequalities, one-contract-per-file */
/* solhint-enable foundry-test-functions */

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { Easyntropy } from "./Easyntropy.sol";
import { EasyntropyConsumer } from "./EasyntropyConsumer.sol";

contract EasyntropyConsumerTest is Test {
  Easyntropy private easyntropy;
  EasyntropyConsumer private subject;
  address public owner;
  address public executor;
  address public user;

  function setUp() public {
    owner = makeAddr("owner");
    user = makeAddr("user");
    executor = makeAddr("executor");
    vm.deal(user, 1000 ether);

    __prank(owner);
    easyntropy = new Easyntropy(executor, 1 wei);
    subject = new EasyntropyConsumerDummy(address(easyntropy));
    __prank(user);
  }

  function test_constructor_setsEntropyAddresses() public view {
    assertEq(address(subject.entropy()), address(easyntropy));
  }

  function test_easyntropyFee_returnsFee() public view {
    assertEq(subject.easyntropyFee(), easyntropy.fee());
  }

  function test_currentBalanceEasyntropy_returnsContractsBalance() public {
    assertEq(easyntropy.balances(address(subject)), 0);
    assertEq(subject.currentBalanceEasyntropy(), 0);

    subject.depositEasyntropy{ value: 1 ether }();

    assertEq(easyntropy.balances(address(subject)), 1 ether);
    assertEq(subject.currentBalanceEasyntropy(), 1 ether);
  }

  function test_depositEasyntropy_depositsFundsAtContractsBalance() public {
    assertEq(easyntropy.balances(address(subject)), 0);
    subject.depositEasyntropy{ value: 1 ether }();
    assertEq(easyntropy.balances(address(subject)), 1 ether);
  }

  function test_withdrawEasyntropy_withdrawsFundsBackToContracts() public {
    EasyntropyConsumerDummy wrappedSubject = new EasyntropyConsumerDummy(address(easyntropy));
    wrappedSubject.depositEasyntropy{ value: 1 ether }();

    // 1st withdraw
    wrappedSubject.internal__withdrawEasyntropy(0.3 ether);
    assertEq(address(wrappedSubject).balance, 0.3 ether);
    assertEq(easyntropy.balances(address(wrappedSubject)), 0.7 ether);

    // 2nd withdraw
    wrappedSubject.internal__withdrawEasyntropy(0.5 ether);
    assertEq(address(wrappedSubject).balance, 0.8 ether);
    assertEq(easyntropy.balances(address(wrappedSubject)), 0.2 ether);
  }

  function test_easyntropyFulfill_failsIfCalledByNotEasyntropy() public {
    vm.expectRevert(EasyntropyConsumer.PermissionDenied.selector);
    subject._easyntropyFulfill(
      1, // requestId
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(2)), // externalSeed
      3 // externalSeedId
    );
  }

  function test_easyntropyFulfill_callsContractDefaultCallback() public {
    __prank(executor);

    vm.expectEmit(true, false, false, false);
    emit EasyntropyConsumerDummy.FulfillmentSucceeded();

    vm.expectEmit(true, true, true, true);
    emit EasyntropyConsumer.FulfillmentSucceeded(
      1, // requestId
      address(subject), // requester
      0x493411d13d63214b2404144a3bc1c0b96adbfb5b75b02b8d07720ea9a77142fd, // seed (based on externalSeed and internalSeed)
      bytes32(uint256(2)), // externalSeed
      3 // externalSeedId
    );

    easyntropy.responseWithCallback(
      1, // requestId
      address(subject), // requester
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(2)), // externalSeed
      3 // externalSeedId
    );
  }

  function test_easyntropyFulfill_emitsFailEventWhenCallbackIsNotDefined() public {
    __prank(executor);

    vm.expectEmit(true, true, true, true);
    emit EasyntropyConsumer.FulfillmentFailed(
      1, // requestId
      address(subject), // requester
      0x493411d13d63214b2404144a3bc1c0b96adbfb5b75b02b8d07720ea9a77142fd, // seed (based on externalSeed and internalSeed)
      bytes32(uint256(2)), // externalSeed
      3 // externalSeedId
    );

    easyntropy.responseWithCallback(
      1, // requestId
      address(subject), // requester
      bytes4(keccak256("easyntropyFulfill__404(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(2)), // externalSeed
      3 // externalSeedId
    );
  }

  function test_easyntropyFulfill_callsContractCustomCallback() public {
    __prank(executor);

    vm.expectEmit(true, false, false, false);
    emit EasyntropyConsumerDummy.CustomFulfillmentSucceeded();

    vm.expectEmit(true, true, true, true);
    emit EasyntropyConsumer.FulfillmentSucceeded(
      1, // requestId
      address(subject), // requester
      0x493411d13d63214b2404144a3bc1c0b96adbfb5b75b02b8d07720ea9a77142fd, // seed (based on externalSeed and internalSeed)
      bytes32(uint256(2)), // externalSeed
      3 // externalSeedId
    );

    easyntropy.responseWithCallback(
      1, // requestId
      address(subject), // requester
      bytes4(keccak256("customFulfill(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(2)), // externalSeed
      3 // externalSeedId
    );
  }

  function test_easyntropyFulfill_callsContractWithCustomCalculateSeed() public {
    __prank(executor);
    subject = new EasyntropyConsumerDummyCustomCalculateSeed(address(easyntropy));

    vm.expectEmit(true, false, false, false);
    emit EasyntropyConsumerDummyCustomCalculateSeed.FulfillmentSucceeded();

    vm.expectEmit(true, true, true, true);
    emit EasyntropyConsumer.FulfillmentSucceeded(
      1, // requestId
      address(subject), // requester
      0x0000000000000000000000000000000000000000000000000000000000000000, // seed (based on externalSeed and internalSeed)
      bytes32(uint256(2)), // externalSeed
      3 // externalSeedId
    );

    easyntropy.responseWithCallback(
      1, // requestId
      address(subject), // requester
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(2)), // externalSeed
      3 // externalSeedId
    );
  }

  function test_easyntropyRequestWithCallback_callsEntropyAsSyntaxSugar() public {
    EasyntropyConsumerDummy wrappedSubject = new EasyntropyConsumerDummy(address(easyntropy));

    payable(address(wrappedSubject)).transfer(10 ether);

    vm.expectEmit(false, true, true, false);
    emit Easyntropy.RequestSubmitted(
      1, // requestId - ignored
      address(wrappedSubject), // requester
      0x774358d3 // bytes4(keccak256("easyntropyFulfill(uint64,bytes32)"));
    );

    wrappedSubject.internal__easyntropyRequestWithCallback();
  }

  function test_easyntropyRequestWithCallback_callsEntropyWithCustomCallbackAsSyntaxSugar() public {
    EasyntropyConsumerDummy wrappedSubject = new EasyntropyConsumerDummy(address(easyntropy));

    payable(address(wrappedSubject)).transfer(10 ether);

    vm.expectEmit(false, true, true, false);
    emit Easyntropy.RequestSubmitted(
      1, // requestId - ignored
      address(wrappedSubject), // requester
      bytes4(keccak256("customFulfill(uint64,bytes32)")) // callbackSelector
    );

    wrappedSubject.internal__easyntropyRequestWithCallback(wrappedSubject.customFulfill.selector);
  }

  // private
  function __prank(address actor) public {
    vm.stopPrank();
    vm.startPrank(actor);
  }
}

contract EasyntropyConsumerDummy is EasyntropyConsumer {
  event FulfillmentSucceeded();
  event CustomFulfillmentSucceeded();

  constructor(address _entropy) EasyntropyConsumer(_entropy) {}

  function easyntropyFulfill(uint64, bytes32) public onlyEasyntropy {
    emit FulfillmentSucceeded();
  }
  function customFulfill(uint64, bytes32) public onlyEasyntropy {
    emit CustomFulfillmentSucceeded();
  }

  function internal__withdrawEasyntropy(uint256 amount) public {
    withdrawEasyntropy(amount);
  }

  function internal__easyntropyRequestWithCallback() public returns (uint64 requestId) {
    requestId = easyntropyRequestWithCallback();
  }

  function internal__easyntropyRequestWithCallback(bytes4 callbackSelector) public returns (uint64 requestId) {
    requestId = easyntropyRequestWithCallback(callbackSelector);
  }
  receive() external payable {}
}

contract EasyntropyConsumerDummyCustomCalculateSeed is EasyntropyConsumer {
  event FulfillmentSucceeded();

  constructor(address _entropy) EasyntropyConsumer(_entropy) {}
  function easyntropyFulfill(uint64, bytes32) public onlyEasyntropy {
    emit FulfillmentSucceeded();
  }
  function calculateSeed(bytes32) internal pure override returns (bytes32 result) {
    result = 0;
  }
}
