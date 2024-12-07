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
  address public vault;
  address public user;

  function setUp() public {
    owner = makeAddr("owner");
    user = makeAddr("user");
    vault = makeAddr("vault");
    vm.deal(user, 1000 ether);

    __prank(owner);
    easyntropy = new Easyntropy(vault, 1 wei);
    subject = new EasyntropyConsumerDummy(address(easyntropy));
    __prank(user);
  }

  function test_constructor_SetsEntropyAddresses() public view {
    assertEq(address(subject.entropy()), address(easyntropy));
  }

  function test_entropyFee_ReturnsFee() public view {
    assertEq(subject.entropyFee(), easyntropy.fee());
  }

  function test__easyntropyFulfill_FailsIfCalledByNotEasyntropy() public {
    vm.expectRevert(EasyntropyConsumer.PermissionDenied.selector);
    subject._easyntropyFulfill(
      1, // requestId
      bytes4(keccak256("easyntropyFulfill(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(2)), // externalSeed
      3 // externalSeedId
    );
  }

  function test__easyntropyFulfill_CallsContractDefaultCallback() public {
    __prank(vault);

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

  function test__easyntropyFulfill_EmitsFailEventWhenCallbackIsNotDefined() public {
    __prank(vault);

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

  function test__easyntropyFulfill_CallsContractCustomCallback() public {
    __prank(vault);

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

  function test__easyntropyFulfill_CallsContractWithCustomCalculateSeed() public {
    __prank(vault);
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

  function test_entropyRequestWithCallback_CallsEntropyAsSyntaxSugar() public {
    EasyntropyConsumerDummy wrappedSubject = new EasyntropyConsumerDummy(address(easyntropy));

    payable(address(wrappedSubject)).transfer(10 ether);

    vm.expectEmit(false, true, true, false);
    emit Easyntropy.RequestSubmitted(
      1, // requestId - ignored
      address(wrappedSubject), // requester
      0x774358d3 // bytes4(keccak256("easyntropyFulfill(uint64,bytes32)"));
    );

    wrappedSubject.internal__entropyRequestWithCallback();
  }

  function test_entropyRequestWithCallback_CallsEntropyWithCustomCallbackAsSyntaxSugar() public {
    EasyntropyConsumerDummy wrappedSubject = new EasyntropyConsumerDummy(address(easyntropy));

    payable(address(wrappedSubject)).transfer(10 ether);

    vm.expectEmit(false, true, true, false);
    emit Easyntropy.RequestSubmitted(
      1, // requestId - ignored
      address(wrappedSubject), // requester
      bytes4(keccak256("customFulfill(uint64,bytes32)")) // callbackSelector
    );

    wrappedSubject.internal__entropyRequestWithCallback(wrappedSubject.customFulfill.selector);
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

  function internal__entropyRequestWithCallback() public returns (uint64 requestId) {
    requestId = entropyRequestWithCallback();
  }

  function internal__entropyRequestWithCallback(bytes4 callbackSelector) public returns (uint64 requestId) {
    requestId = entropyRequestWithCallback(callbackSelector);
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
