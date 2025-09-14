// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "../Easyntropy/EasyntropyConsumer.sol";

contract Widthrawing is EasyntropyConsumer {
  constructor(address _easyntropy) EasyntropyConsumer(_easyntropy) {}

  function withdrawFromOracle(uint256 amount) public {
    // add your own permission restrictions here...

    easyntropyWithdraw(amount);
  }

  receive() external payable {}
}
