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
      1, // sequenceNumber
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
      1, // sequenceNumber
      address(subject), // requester
      0xb37150ceb7e138645bfe4dfcef9a75073e1d7aa14c524dfdd20d3f751fad1084, // seed (based on externalSeed and internalSeed)
      bytes32(uint256(2)), // externalSeed
      3, // externalSeedId
      0xada5013122d395ba3c54772283fb069b10426056ef8ca54750cb9bb552a59e7d // internalSeed
    );

    easyntropy.responseWithCallback(
      1, // sequenceNumber
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
      1, // sequenceNumber
      address(subject), // requester
      0xb37150ceb7e138645bfe4dfcef9a75073e1d7aa14c524dfdd20d3f751fad1084, // seed (based on externalSeed and internalSeed)
      bytes32(uint256(2)), // externalSeed
      3, // externalSeedId
      0xada5013122d395ba3c54772283fb069b10426056ef8ca54750cb9bb552a59e7d // internalSeed
    );

    easyntropy.responseWithCallback(
      1, // sequenceNumber
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
      1, // sequenceNumber
      address(subject), // requester
      0xb37150ceb7e138645bfe4dfcef9a75073e1d7aa14c524dfdd20d3f751fad1084, // seed (based on externalSeed and internalSeed)
      bytes32(uint256(2)), // externalSeed
      3, // externalSeedId
      0xada5013122d395ba3c54772283fb069b10426056ef8ca54750cb9bb552a59e7d // internalSeed
    );

    easyntropy.responseWithCallback(
      1, // sequenceNumber
      address(subject), // requester
      bytes4(keccak256("customFulfill(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(2)), // externalSeed
      3 // externalSeedId
    );
  }

  function test__easyntropyFulfill_CallsContractWithCustomInternalSeed() public {
    __prank(vault);
    subject = new EasyntropyConsumerDummyCustomInternalSeed(address(easyntropy));

    vm.expectEmit(true, false, false, false);
    emit EasyntropyConsumerDummyCustomInternalSeed.FulfillmentSucceeded();

    vm.expectEmit(true, true, true, true);
    emit EasyntropyConsumer.FulfillmentSucceeded(
      1, // sequenceNumber
      address(subject), // requester
      0xabbb5caa7dda850e60932de0934eb1f9d0f59695050f761dc64e443e5030a569, // seed (based on externalSeed and internalSeed)
      bytes32(uint256(2)), // externalSeed
      3, // externalSeedId
      0 // internalSeed
    );

    easyntropy.responseWithCallback(
      1, // sequenceNumber
      address(subject), // requester
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
  event CustomFulfillmentSucceeded();

  constructor(address _entropy) EasyntropyConsumer(_entropy) {}
  function easyntropyFulfill(uint64, bytes32) public onlyEasyntropy {
    emit FulfillmentSucceeded();
  }
  function customFulfill(uint64, bytes32) public onlyEasyntropy {
    emit CustomFulfillmentSucceeded();
  }
}

contract EasyntropyConsumerDummyCustomInternalSeed is EasyntropyConsumer {
  event FulfillmentSucceeded();

  constructor(address _entropy) EasyntropyConsumer(_entropy) {}
  function easyntropyFulfill(uint64, bytes32) public onlyEasyntropy {
    emit FulfillmentSucceeded();
  }
  function calculateInternalSeed() internal pure override returns (bytes32 result) {
    result = 0;
  }
}
