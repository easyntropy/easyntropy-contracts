/* solhint-disable func-name-mixedcase, gas-strict-inequalities, one-contract-per-file */
/* solhint-enable foundry-test-functions */

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { IEntropyConsumer } from "pyth/IEntropyConsumer.sol";
import { IEntropyV2 } from "pyth/IEntropyV2.sol";
import { EntropyStructsV2 } from "pyth/EntropyStructsV2.sol";
import { IEntropy } from "pyth/IEntropy.sol";
import { EntropyStructs } from "pyth/EntropyStructs.sol";
import { Easyntropy } from "./Easyntropy.sol";

import { PythNetworkToEasyntropyAdapter } from "./PythNetworkToEasyntropyAdapter.sol";

contract PythNetworkToEasyntropyAdapterTest is Test {
  Easyntropy private easyntropy;
  PythNetworkToEasyntropyAdapter private subject;
  PythEntropyV2Consumer private pythEntropyV2Consumer;
  PythEntropyConsumer private pythEntropyConsumer;
  address public owner;
  address public executor;
  address public user;
  bytes4 public defaultEasyntropyCallbackSymbol;

  function setUp() public {
    defaultEasyntropyCallbackSymbol = bytes4(keccak256("easyntropyFulfill(uint64,bytes32)"));
    owner = makeAddr("owner");
    user = makeAddr("user");
    executor = makeAddr("executor");
    vm.deal(owner, 1 ether);
    vm.deal(user, 1 ether);

    __prank(owner);
    easyntropy = new Easyntropy(executor, 1 wei);
    subject = new PythNetworkToEasyntropyAdapter(address(easyntropy));
    pythEntropyV2Consumer = new PythEntropyV2Consumer(address(subject));
    pythEntropyConsumer = new PythEntropyConsumer(address(subject), address(subject));
    vm.deal(address(pythEntropyV2Consumer), 1 ether);

    __prank(user);
  }

  function test_constructor_setsOwner() public view {
    assertEq(subject.owner(), owner);
  }

  function test_constructor_setsEasyntropy() public view {
    assertEq(address(subject.easyntropy()), address(easyntropy));
  }

  function test_setEasyentropy_setsEasyntropy() public {
    __prank(owner);
    address newEasyntropy = makeAddr("newEasyntropy");
    subject.setEasyentropy(newEasyntropy);
    assertEq(address(subject.easyntropy()), newEasyntropy);
  }

  function test_setEasyentropy_emitsEasyentropySetEvent() public {
    __prank(owner);
    address newEasyntropy = makeAddr("newEasyntropy");

    vm.expectEmit(true, true, true, true);
    emit PythNetworkToEasyntropyAdapter.EasyentropySet(newEasyntropy);
    subject.setEasyentropy(newEasyntropy);
  }

  function test_setEasyentropy_failsWhenExecutedByNotOwner() public {
    address newEasyntropy = makeAddr("newEasyntropy");
    vm.expectRevert(Easyntropy.PermissionDenied.selector);
    subject.setEasyentropy(newEasyntropy);
  }

  function test_requestV2_succeedsWithEnoughEth() public {
    uint64 requestId = subject.requestV2{ value: subject.easyntropyFee() }();
    assertEq(subject.requesters(requestId), user);
  }

  function test_requestV2_failsWithNotEnoughEth() public {
    vm.expectRevert(PythNetworkToEasyntropyAdapter.NotEnoughEth.selector);
    subject.requestV2{ value: 0 }();
  }

  function test_requestV2_emitsRequestSubmittedEvent() public {
    vm.expectEmit(true, true, true, false);
    emit Easyntropy.RequestSubmitted(1, address(subject), defaultEasyntropyCallbackSymbol);
    subject.requestV2{ value: subject.easyntropyFee() }();
  }

  function test_getFeeV2_returnsFee() public view {
    uint128 fee = uint128(easyntropy.fee());
    assertEq(subject.getFeeV2(), fee);
  }

  function test_getDefaultProvider_returnsEasyntropyAddress() public view {
    assertEq(subject.getDefaultProvider(), address(easyntropy));
  }

  function test_getRequestV2_returnsCorrectRequest() public {
    uint64 requestId = subject.requestV2{ value: subject.easyntropyFee() }();

    EntropyStructsV2.Request memory req = subject.getRequestV2(address(0), requestId);

    assertEq(req.provider, address(easyntropy));
    assertEq(req.sequenceNumber, requestId);
    assertEq(req.requester, user);
  }

  function test_getProviderInfoV2_returnsCorrectInfo() public view {
    EntropyStructsV2.ProviderInfo memory info = subject.getProviderInfoV2(address(0));

    assertEq(info.feeManager, address(easyntropy));
  }

  function test_requestV2_withGasLimit_delegatesToMainRequest() public {
    vm.expectEmit(true, true, true, false);
    emit Easyntropy.RequestSubmitted(1, address(subject), defaultEasyntropyCallbackSymbol);
    subject.requestV2{ value: subject.easyntropyFee() }(10000);
  }

  function test_requestV2_withProvider_delegatesToMainRequest() public {
    vm.expectEmit(true, true, true, false);
    emit Easyntropy.RequestSubmitted(1, address(subject), defaultEasyntropyCallbackSymbol);
    subject.requestV2{ value: subject.easyntropyFee() }(makeAddr("provider"), 10000);
  }

  function test_requestV2_withProviderAndUserRandomNumber_delegatesToMainRequest() public {
    vm.expectEmit(true, true, true, false);
    emit Easyntropy.RequestSubmitted(1, address(subject), defaultEasyntropyCallbackSymbol);
    subject.requestV2{ value: subject.easyntropyFee() }(makeAddr("provider"), keccak256("random"), 10000);
  }

  function test_getFeeV2_withGasLimit_returnsFee() public view {
    assertEq(subject.getFeeV2(10000), subject.easyntropyFee());
  }

  function test_getFeeV2_withProvider_returnsFee() public {
    assertEq(subject.getFeeV2(makeAddr("provider"), 10000), subject.easyntropyFee());
  }

  function test_requestWithCallback_succeedsWithEnoughEth() public {
    vm.expectEmit(true, true, true, false);
    emit Easyntropy.RequestSubmitted(1, address(subject), defaultEasyntropyCallbackSymbol);
    subject.requestWithCallback{ value: subject.easyntropyFee() }(makeAddr("provider"), keccak256("random"));
  }

  function test_requestWithCallback_failsWithNotEnoughEth() public {
    vm.expectRevert(PythNetworkToEasyntropyAdapter.NotEnoughEth.selector);
    subject.requestWithCallback{ value: 0 }(makeAddr("provider"), keccak256("random"));
  }

  function test_getFee_returnsFee() public {
    assertEq(subject.getFee(makeAddr("provider")), subject.easyntropyFee());
  }

  function test_getAccruedPythFees_returnsZero() public view {
    assertEq(subject.getAccruedPythFees(), 0);
  }

  function test_getProviderInfo_returnsCorrectInfo() public {
    EntropyStructs.ProviderInfo memory info = subject.getProviderInfo(makeAddr("provider"));
    assertEq(info.feeManager, address(easyntropy));
  }

  function test_getRequest_returnsCorrectRequest() public {
    uint64 requestId = subject.requestWithCallback{ value: subject.easyntropyFee() }(makeAddr("provider"), keccak256("random"));
    EntropyStructs.Request memory req = subject.getRequest(makeAddr("provider"), requestId);

    assertEq(req.provider, address(easyntropy));
    assertEq(req.sequenceNumber, requestId);
    assertEq(req.requester, user);
    assertTrue(req.isRequestWithCallback);
  }

  function test_easyntropyFulfill_callsConsumerCallbackFromPythV2Consumer() public {
    uint64 requestId = pythEntropyV2Consumer.requestRandomValue{ value: subject.easyntropyFee() }();
    bytes32 seed = keccak256("test_seed");

    __prank(executor);
    vm.expectEmit(true, true, true, false);
    emit PythEntropyV2Consumer.CallbackReceived(requestId, address(subject), seed);
    easyntropy.responseWithCallback(requestId, address(subject), defaultEasyntropyCallbackSymbol, seed, 1);
  }

  function test_easyntropyFulfill_callsConsumerCallbackFromPythV1Consumer() public {
    uint64 requestId = pythEntropyConsumer.requestRandomValue{ value: subject.easyntropyFee() }();
    bytes32 seed = keccak256("test_seed");

    __prank(executor);
    vm.expectEmit(true, true, true, false);
    emit PythEntropyConsumer.CallbackReceived(requestId, address(subject), seed);
    easyntropy.responseWithCallback(requestId, address(subject), defaultEasyntropyCallbackSymbol, seed, 1);
  }

  function test_easyntropyFulfill_deletesRequester() public {
    uint64 requestId = pythEntropyV2Consumer.requestRandomValue{ value: subject.easyntropyFee() }();
    bytes32 seed = keccak256("test_seed");

    __prank(executor);
    assertEq(subject.requesters(requestId), address(pythEntropyV2Consumer));
    easyntropy.responseWithCallback(requestId, address(subject), defaultEasyntropyCallbackSymbol, seed, 1);
    assertEq(subject.requesters(requestId), address(0));
  }

  function test_easyntropyFulfill_failsWhenCalledByNotEasyntropy() public {
    uint64 requestId = subject.requestV2{ value: subject.easyntropyFee() }();
    bytes32 seed = keccak256("test_seed");

    vm.expectRevert(Easyntropy.PermissionDenied.selector);
    subject.easyntropyFulfill(requestId, seed);
  }

  function test_register_revertsNotImplemented() public {
    vm.expectRevert(PythNetworkToEasyntropyAdapter.NotImplemented.selector);
    subject.register(1 wei, bytes32(0), "", 1, "");
  }

  function test_withdraw_revertsNotImplemented() public {
    vm.expectRevert(PythNetworkToEasyntropyAdapter.NotImplemented.selector);
    subject.withdraw(1 wei);
  }

  function test_withdrawAsFeeManager_revertsNotImplemented() public {
    vm.expectRevert(PythNetworkToEasyntropyAdapter.NotImplemented.selector);
    subject.withdrawAsFeeManager(makeAddr("provider"), 1 wei);
  }

  function test_request_revertsNotImplemented() public {
    vm.expectRevert(PythNetworkToEasyntropyAdapter.NotImplemented.selector);
    subject.request(makeAddr("provider"), bytes32(0), false);
  }

  function test_reveal_revertsNotImplemented() public {
    vm.expectRevert(PythNetworkToEasyntropyAdapter.NotImplemented.selector);
    subject.reveal(makeAddr("provider"), 1, bytes32(0), bytes32(0));
  }

  function test_revealWithCallback_revertsNotImplemented() public {
    vm.expectRevert(PythNetworkToEasyntropyAdapter.NotImplemented.selector);
    subject.revealWithCallback(makeAddr("provider"), 1, bytes32(0), bytes32(0));
  }

  function test_setProviderFee_revertsNotImplemented() public {
    vm.expectRevert(PythNetworkToEasyntropyAdapter.NotImplemented.selector);
    subject.setProviderFee(1 wei);
  }

  function test_setProviderFeeAsFeeManager_revertsNotImplemented() public {
    vm.expectRevert(PythNetworkToEasyntropyAdapter.NotImplemented.selector);
    subject.setProviderFeeAsFeeManager(makeAddr("provider"), 1 wei);
  }

  function test_setProviderUri_revertsNotImplemented() public {
    vm.expectRevert(PythNetworkToEasyntropyAdapter.NotImplemented.selector);
    subject.setProviderUri("");
  }

  function test_setFeeManager_revertsNotImplemented() public {
    vm.expectRevert(PythNetworkToEasyntropyAdapter.NotImplemented.selector);
    subject.setFeeManager(makeAddr("feeManager"));
  }

  function test_setMaxNumHashes_revertsNotImplemented() public {
    vm.expectRevert(PythNetworkToEasyntropyAdapter.NotImplemented.selector);
    subject.setMaxNumHashes(1);
  }

  function test_setDefaultGasLimit_revertsNotImplemented() public {
    vm.expectRevert(PythNetworkToEasyntropyAdapter.NotImplemented.selector);
    subject.setDefaultGasLimit(1);
  }

  function test_advanceProviderCommitment_revertsNotImplemented() public {
    vm.expectRevert(PythNetworkToEasyntropyAdapter.NotImplemented.selector);
    subject.advanceProviderCommitment(makeAddr("provider"), 1, bytes32(0));
  }

  function test_constructUserCommitment_revertsNotImplemented() public {
    vm.expectRevert(PythNetworkToEasyntropyAdapter.NotImplemented.selector);
    subject.constructUserCommitment(bytes32(0));
  }

  function test_combineRandomValues_revertsNotImplemented() public {
    vm.expectRevert(PythNetworkToEasyntropyAdapter.NotImplemented.selector);
    subject.combineRandomValues(bytes32(0), bytes32(0), bytes32(0));
  }

  // private
  function __prank(address actor) public {
    vm.stopPrank();
    vm.startPrank(actor);
  }
}

contract PythEntropyV2Consumer is IEntropyConsumer {
  event CallbackReceived(uint64 indexed sequence, address indexed provider, bytes32 randomNumber);

  IEntropyV2 public entropy;

  constructor(address _entropy) {
    entropy = IEntropyV2(_entropy);
  }

  function getEntropy() internal view override returns (address entropyAddr) {
    entropyAddr = address(entropy);
  }

  function entropyCallback(uint64 sequence, address provider, bytes32 randomNumber) internal override {
    emit CallbackReceived(sequence, provider, randomNumber);
  }

  function requestRandomValue() external payable returns (uint64 requestId) {
    requestId = entropy.requestV2{ value: msg.value }();
  }
}

contract PythEntropyConsumer is IEntropyConsumer {
  event CallbackReceived(uint64 indexed sequence, address indexed provider, bytes32 randomNumber);

  IEntropy public entropy;
  address public entropyProvider;

  constructor(address _entropy, address _entropyProvider) {
    entropy = IEntropy(_entropy);
    entropyProvider = _entropyProvider;
  }

  function getEntropy() internal view override returns (address entropyAddr) {
    entropyAddr = address(entropy);
  }

  function entropyCallback(uint64 sequence, address provider, bytes32 randomNumber) internal override {
    emit CallbackReceived(sequence, provider, randomNumber);
  }

  function requestRandomValue() external payable returns (uint64 requestId) {
    uint128 entropyRequestFee = entropy.getFee(entropyProvider);
    bytes32 semiRandomSeed = keccak256(abi.encodePacked(block.number, tx.gasprice));
    requestId = entropy.requestWithCallback{ value: entropyRequestFee }(entropyProvider, semiRandomSeed);
  }
}
