// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract InteractionsTest is Test {
  FundMe public fundMe;

  address USER = address(1);
  uint256 constant SEND_VALUE = 1 ether;
  uint256 constant STARTING_BALANCE = 10000 ether;
  uint256 constant GAS_PRICE = 1;

  function setUp() external {
    DeployFundMe deploy = new DeployFundMe();
    fundMe = deploy.run();
    vm.deal(USER, STARTING_BALANCE);
  }

  function testUserCanFundInteractions() public {
    FundFundMe fundFundMe = new FundFundMe();
    fundFundMe.fundFundMe(address(fundMe));

    WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
    withdrawFundMe.withdrawFundMe(address(fundMe));
    assertEq(address(fundMe).balance, 0);
  }
}
