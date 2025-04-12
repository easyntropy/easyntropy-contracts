/* solhint-disable func-name-mixedcase, gas-strict-inequalities */
/* solhint-enable foundry-test-functions */

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { Easyntropy } from "../Easyntropy/Easyntropy.sol";
import { Widthrawing } from "./Widthrawing.sol";

contract WidthrawingTest is Test {
  Easyntropy private easyntropy;
  Widthrawing private subject;
  address public user;
  address public executor;

  function setUp() public {
    user = makeAddr("user");
    executor = makeAddr("executor");
    vm.deal(user, 1 ether);
    vm.startPrank(user);

    easyntropy = new Easyntropy(executor, 1 wei);
    subject = new Widthrawing(address(easyntropy));
  }

  function test_constructor_setsEntropyAddresses() public view {
    assertEq(address(subject.entropy()), address(easyntropy));
  }

  function test_withdrawFromOracle() public {
    assertEq(address(subject).balance, 0 ether);
    assertEq(subject.easyntropyCurrentBalance(), 0 ether);

    // deposit
    subject.easyntropyDeposit{ value: 0.5 ether }();
    assertEq(address(subject).balance, 0 ether);
    assertEq(subject.easyntropyCurrentBalance(), 0.5 ether);

    // withdraw
    subject.withdrawFromOracle(0.3 ether);
    assertEq(address(subject).balance, 0.3 ether);
    assertEq(subject.easyntropyCurrentBalance(), 0.2 ether);
  }
}
