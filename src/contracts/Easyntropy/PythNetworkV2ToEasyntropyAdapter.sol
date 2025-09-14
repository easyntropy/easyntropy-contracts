// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./IEasyntropy.sol";
import "./EasyntropyConsumer.sol";
import "pyth/IEntropyConsumer.sol";
import "pyth/IEntropyV2.sol";

contract PythNetworkV2ToEasyntropyAdapter is IEntropyV2, EasyntropyConsumer {
  address public owner;
  mapping(uint64 requestId => address requester) public requesters;

  event EasyentropySet(address indexed easyntropy);
  error NotEnoughEth();

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

  function getRequestV2(
    address, // provider - ignored
    uint64 sequenceNumber
  ) external view returns (EntropyStructsV2.Request memory req) {
    req = EntropyStructsV2.Request({
      provider: address(easyntropy),
      sequenceNumber: sequenceNumber,
      requester: requesters[sequenceNumber],
      numHashes: 0, // dummy data
      commitment: bytes32(0), // dummy data
      blockNumber: 0, // dummy data
      useBlockhash: false, // dummy data
      callbackStatus: 0, // dummy data
      gasLimit10k: 0 // dummy data
    });
  }

  function getProviderInfoV2(
    address // provider - ignored
  ) external view returns (EntropyStructsV2.ProviderInfo memory info) {
    info = EntropyStructsV2.ProviderInfo({
      feeManager: address(easyntropy),
      feeInWei: 0, // dummy data
      accruedFeesInWei: 0, // dummy data
      originalCommitment: bytes32(0), // dummy data
      originalCommitmentSequenceNumber: 0, // dummy data
      commitmentMetadata: "", // dummy data
      uri: "", // dummy data
      endSequenceNumber: 0, // dummy data
      sequenceNumber: 0, // dummy data
      currentCommitment: bytes32(0), // dummy data
      currentCommitmentSequenceNumber: 0, // dummy data
      maxNumHashes: 0, // dummy data
      defaultGasLimit: 0 // dummy data
    });
  }

  // --- dummy IEntropyV2 delegations ---------------------------------------
  function requestV2(
    uint32 // gasLimit - ignored
  ) external payable returns (uint64 assignedSequenceNumber) {
    assignedSequenceNumber = this.requestV2();
  }

  function requestV2(
    address, // provider - ignored
    uint32 // gasLimit - ignored
  ) external payable returns (uint64 assignedSequenceNumber) {
    assignedSequenceNumber = this.requestV2();
  }

  function requestV2(
    address, // provider - ignored
    bytes32, // userRandomNumber - ignored
    uint32 // gasLimit - ignored
  ) external payable returns (uint64 assignedSequenceNumber) {
    assignedSequenceNumber = this.requestV2();
  }

  function getFeeV2(
    uint32 // gasLimit - ignored
  ) external view returns (uint128 feeAmount) {
    feeAmount = this.getFeeV2();
  }

  function getFeeV2(
    address, // provider - ignored
    uint32 // gasLimit - ignored
  ) external view returns (uint128 feeAmount) {
    feeAmount = this.getFeeV2();
  }
}
