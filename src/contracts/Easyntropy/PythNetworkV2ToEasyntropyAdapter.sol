// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "pyth/IEntropyConsumer.sol";
import "pyth/IEntropyV2.sol";
import "pyth/IEntropy.sol";
import "./IEasyntropy.sol";
import "./EasyntropyConsumer.sol";

contract PythNetworkV2ToEasyntropyAdapter is IEntropyV2, IEntropy, EasyntropyConsumer {
  address public owner;
  mapping(uint64 requestId => address requester) public requesters;

  event EasyentropySet(address indexed easyntropy);
  error NotEnoughEth();
  error NotImplemented();

  modifier onlyOwner() {
    if (msg.sender != owner) revert PermissionDenied();
    _;
  }

  constructor(address _easyntropy) EasyntropyConsumer(_easyntropy) {
    owner = msg.sender;
  }

  function setEasyentropy(address _easyntropy) public onlyOwner {
    easyntropy = IEasyntropy(_easyntropy);
    emit EasyentropySet(_easyntropy);
  }

  //
  // --- Easyntropy response ------------------------------------------------
  function easyntropyFulfill(uint64 requestId, bytes32 seed) external onlyEasyntropy {
    address requester = requesters[requestId];
    delete requesters[requestId];
    IEntropyConsumer(requester)._entropyCallback(requestId, address(easyntropy), seed);
  }

  //
  // --- IEntropyV2 implementation ------------------------------------------
  // ------------------------------------------------------------------------
  function requestV2() external payable returns (uint64 assignedSequenceNumber) {
    if (msg.value < easyntropyFee()) revert NotEnoughEth();
    assignedSequenceNumber = easyntropyRequestWithCallback();
    requesters[assignedSequenceNumber] = msg.sender;
  }

  function getFeeV2() external view returns (uint128 feeAmount) {
    feeAmount = uint128(easyntropyFee());
  }

  function getDefaultProvider() external view returns (address provider) {
    provider = address(easyntropy);
  }

  // --- IEntropyV2 dummy implementations -----------------------------------
  function getRequestV2(
    address, // provider
    uint64 sequenceNumber
  ) external view returns (EntropyStructsV2.Request memory req) {
    req = EntropyStructsV2.Request({
      provider: address(easyntropy),
      sequenceNumber: sequenceNumber,
      requester: requesters[sequenceNumber],
      // rest are dummy data
      numHashes: 0,
      commitment: bytes32(0),
      blockNumber: 0,
      useBlockhash: false,
      callbackStatus: 0,
      gasLimit10k: 0
    });
  }

  function getProviderInfoV2(
    address // provider
  ) external view returns (EntropyStructsV2.ProviderInfo memory info) {
    info = EntropyStructsV2.ProviderInfo({
      feeManager: address(easyntropy),
      // rest are dummy data
      feeInWei: 0,
      accruedFeesInWei: 0,
      originalCommitment: bytes32(0),
      originalCommitmentSequenceNumber: 0,
      commitmentMetadata: "",
      uri: "",
      endSequenceNumber: 0,
      sequenceNumber: 0,
      currentCommitment: bytes32(0),
      currentCommitmentSequenceNumber: 0,
      maxNumHashes: 0,
      defaultGasLimit: 0
    });
  }

  // --- IEntropyV2 delegations ---------------------------------------------
  function requestV2(
    uint32 // gasLimit
  ) external payable returns (uint64 assignedSequenceNumber) {
    assignedSequenceNumber = this.requestV2();
  }

  function requestV2(
    address, // provider
    uint32 // gasLimit
  ) external payable returns (uint64 assignedSequenceNumber) {
    assignedSequenceNumber = this.requestV2();
  }

  function requestV2(
    address, // provider
    bytes32, // userRandomNumber
    uint32 // gasLimit
  ) external payable returns (uint64 assignedSequenceNumber) {
    assignedSequenceNumber = this.requestV2();
  }

  function getFeeV2(
    uint32 // gasLimit
  ) external view returns (uint128 feeAmount) {
    feeAmount = this.getFeeV2();
  }

  function getFeeV2(
    address, // provider
    uint32 // gasLimit
  ) external view returns (uint128 feeAmount) {
    feeAmount = this.getFeeV2();
  }

  //
  // --- IEntropy implementation --------------------------------------------
  // ------------------------------------------------------------------------
  function requestWithCallback(
    address, // provider
    bytes32 // userRandomNumber
  ) external payable returns (uint64 assignedSequenceNumber) {
    if (msg.value < easyntropyFee()) revert NotEnoughEth();
    assignedSequenceNumber = easyntropyRequestWithCallback();
    requesters[assignedSequenceNumber] = msg.sender;
  }

  function getFee(
    address // provider
  ) external view returns (uint128 feeAmount) {
    feeAmount = uint128(easyntropyFee());
  }

  // --- IEntropy dummy implementations -------------------------------------
  function getAccruedPythFees() external pure returns (uint128 accruedPythFeesInWei) {
    accruedPythFeesInWei = 0;
  }

  function getProviderInfo(
    address // provider
  ) external view returns (EntropyStructs.ProviderInfo memory info) {
    info = EntropyStructs.ProviderInfo({
      feeManager: address(easyntropy),
      // rest are dummy data
      feeInWei: 0,
      accruedFeesInWei: 0,
      originalCommitment: bytes32(0),
      originalCommitmentSequenceNumber: 0,
      commitmentMetadata: "",
      uri: "",
      endSequenceNumber: 0,
      sequenceNumber: 0,
      currentCommitment: bytes32(0),
      currentCommitmentSequenceNumber: 0,
      maxNumHashes: 0
    });
  }

  function getRequest(
    address, // provider
    uint64 sequenceNumber
  ) external view returns (EntropyStructs.Request memory req) {
    req = EntropyStructs.Request({
      provider: address(easyntropy),
      sequenceNumber: sequenceNumber,
      requester: requesters[sequenceNumber],
      // rest are dummy data
      numHashes: 0,
      commitment: bytes32(0),
      blockNumber: 0,
      useBlockhash: false,
      isRequestWithCallback: true
    });
  }

  // solhint-disable gas-named-return-values
  function register(
    uint128, // feeInWei
    bytes32, // commitment
    bytes calldata, // commitmentMetadata
    uint64, // chainLength
    bytes calldata // ur
  ) external pure {
    revert NotImplemented();
  }

  function withdraw(
    uint128 // amount
  ) external pure {
    revert NotImplemented();
  }

  function withdrawAsFeeManager(
    address, // provider
    uint128 // amount
  ) external pure {
    revert NotImplemented();
  }

  function request(
    address, // provider
    bytes32, // userCommitment
    bool // useBlockHash
  ) external payable returns (uint64) {
    revert NotImplemented();
  }

  function reveal(
    address, // provider
    uint64, // sequenceNumber
    bytes32, // userRevelation
    bytes32 // providerRevelation
  )
    external
    pure
    returns (
      bytes32 // randomNumber
    )
  {
    revert NotImplemented();
  }

  function revealWithCallback(
    address, // provider
    uint64, // sequenceNumber
    bytes32, // userRandomNumber
    bytes32 // providerRevelation
  ) external pure {
    revert NotImplemented();
  }

  function setProviderFee(
    uint128 // newFeeInWei
  ) external pure {
    revert NotImplemented();
  }

  function setProviderFeeAsFeeManager(
    address, // provider
    uint128 // newFeeInWei
  ) external pure {
    revert NotImplemented();
  }

  function setProviderUri(
    bytes calldata // newUri
  ) external pure {
    revert NotImplemented();
  }

  function setFeeManager(
    address // manager
  ) external pure {
    revert NotImplemented();
  }

  function setMaxNumHashes(
    uint32 // maxNumHashes
  ) external pure {
    revert NotImplemented();
  }

  function setDefaultGasLimit(
    uint32 // gasLimit
  ) external pure {
    revert NotImplemented();
  }

  function advanceProviderCommitment(
    address, // provider
    uint64, // advancedSequenceNumber
    bytes32 // providerRevelation
  ) external pure {
    revert NotImplemented();
  }

  function constructUserCommitment(
    bytes32 // userRandomness
  )
    external
    pure
    returns (
      bytes32 // userCommitment
    )
  {
    revert NotImplemented();
  }

  function combineRandomValues(
    bytes32, // userRandomness
    bytes32, // providerRandomness
    bytes32 // blockHash
  )
    external
    pure
    returns (
      bytes32 // combinedRandomness
    )
  {
    revert NotImplemented();
  }
}
