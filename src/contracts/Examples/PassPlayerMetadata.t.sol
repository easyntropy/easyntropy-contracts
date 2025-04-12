/* solhint-disable func-name-mixedcase, gas-strict-inequalities */
/* solhint-enable foundry-test-functions */

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { Easyntropy } from "../Easyntropy/Easyntropy.sol";
import { PassPlayerMetadata } from "./PassPlayerMetadata.sol";

contract PassPlayerMetadataTest is Test {
  Easyntropy private easyntropy;
  PassPlayerMetadata private subject;
  address public user;
  address public executor;

  function setUp() public {
    user = makeAddr("user");
    executor = makeAddr("executor");
    vm.deal(user, 1 ether);
    vm.startPrank(user);

    easyntropy = new Easyntropy(executor, 1 wei);
    subject = new PassPlayerMetadata(address(easyntropy));
  }

  function test_constructor_setsEntropyAddresses() public view {
    assertEq(address(subject.entropy()), address(easyntropy));
  }

  function test_easyntropyFee_returnsExpectedFeeFuzzy(uint256 fee) public {
    easyntropy.setFee(fee);
    assertEq(subject.easyntropyFee(), easyntropy.fee());
  }

  function test_startTrainingGladiator_failsIfNotEnoughMoneyIsSent() public {
    vm.expectRevert(PassPlayerMetadata.NotEnoughEth.selector);
    subject.startTrainingGladiator{ value: 0 }(1);
  }

  function test_startTrainingGladiator_addsEntryToPendingRequests() public {
    uint64 requestId = subject.startTrainingGladiator{ value: subject.easyntropyFee() }(1);

    uint64 gladiatorId = subject.pendingRequests(requestId);
    uint8 gladiatorStrength = subject.gladiators(gladiatorId);
    assertEq(gladiatorStrength, 1);
  }

  function test_startTrainingGladiator_callsEasyntropy() public {
    vm.expectEmit(true, true, true, true);
    emit Easyntropy.RequestSubmitted(
      1, // requestId
      address(subject), // sender
      bytes4(keccak256("trainGladiator(uint64,bytes32)")) // callbackSelector
    );
    subject.startTrainingGladiator{ value: subject.easyntropyFee() }(1);
  }

  function test_easyntropyFullfill_failsWhenCalledByNonOracle() public {
    vm.expectRevert(); // revert due to permissions, only executor can call this function
    subject.trainGladiator(
      1, // requestId
      bytes32(uint256(2)) // externalSeed
    );
  }

  function test_trainGladiator() public {
    uint64 gladiatorId = 1;
    uint64 requestId = subject.startTrainingGladiator{ value: subject.easyntropyFee() }(gladiatorId);

    vm.startPrank(executor);
    easyntropy.responseWithCallback(
      requestId,
      address(subject), // requester
      bytes4(keccak256("trainGladiator(uint64,bytes32)")), // callbackSelector
      bytes32(uint256(5)), // externalSeed
      3 // externalSeedId
    );

    uint8 gladiatorStrength = subject.gladiators(gladiatorId);
    assertEq(gladiatorStrength, 5); // taken from the seed
  }
}
