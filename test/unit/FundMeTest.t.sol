// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { Test, console } from "forge-std/Test.sol";
import { FundMe } from "../../src/FundMe.sol";
import { DeployFundMe } from '../../script/DeployFundMe.s.sol';

contract FundMeTest is Test {
  FundMe fundMe;
  address USER = makeAddr("user");
  uint256 constant SEND_VALUE = 0.1 ether;
  uint256 constant STARTING_BALANCE = 1000 ether;
  uint256 constant GAS_PRICE = 1;

  modifier funded() {
    vm.prank(USER); // the next transaction will be sent by USER
    fundMe.fund{ value: SEND_VALUE }();
    _;
  }

  function setUp() external {
    DeployFundMe deployFundMe = new DeployFundMe();
    fundMe = deployFundMe.run();
    vm.deal(USER,STARTING_BALANCE);
  }

  function testMinimumDolarIsFive() public {
    assertEq(fundMe.MINIMUM_USD(), 5e18);
  }

  function testOwnerIsMsgSender() public {
    assertEq(fundMe.getOwner(), msg.sender);
  }

  function testPriceFeedVersionIsAccurate() public {
    uint256 version = fundMe.getVersion();
    assertEq(version, 4);
  }

  function testFundFailsWithoutEnoughtEther() public {
    vm.expectRevert("You need to spend more ETH!");
    fundMe.fund{ value: 1 }();
  }

  function testFundUpdatesFundedDataStructure() public funded {
    uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
    assertEq(amountFunded, SEND_VALUE);
  }

  function testAddsFunderToArrayOfFunders() public funded {
    address funder = fundMe.getFunder(0);
    assertEq(funder, USER);
  }

  function testOnlyOwnerCanWithdraw() public funded {
    vm.expectRevert();
    vm.prank(USER);
    fundMe.withdraw();
  }

  function testWithdrawWithASingleFunder() public funded {
    // Arrange
    uint256 startingOwnerBalance = fundMe.getOwner().balance;
    uint256 startingFundMeBalance = address(fundMe).balance;

    // Act
    uint256 gasStarts = gasleft();
    vm.txGasPrice(GAS_PRICE);
    vm.prank(fundMe.getOwner());
    fundMe.withdraw();
    uint256 gasEnds = gasleft(); 
    uint256 gasUsed = (gasStarts - gasEnds) * tx.gasprice;
    console.log(gasUsed);

    // Assert
    uint256 endingOwnerBalance = fundMe.getOwner().balance;
    uint256 endingFundMeBalance = address(fundMe).balance;
    assertEq(endingFundMeBalance, 0);
    assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
  }

  function testWithdrawWithMultipleFunders() public funded {
    uint160 numberOfFunders = 10;
    uint160 startingFunderIndex = 2;

    for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
      hoax(address(i), SEND_VALUE);
      fundMe.fund{ value: SEND_VALUE }();
    }

    uint256 startingOwnerBalance  = fundMe.getOwner().balance;
    uint256 startingFundMeBalance = address(fundMe).balance;
    vm.startPrank(fundMe.getOwner());
    fundMe.withdraw();
    vm.stopPrank();

    // Assert
    assert(address(fundMe).balance == 0);
    assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
  }
}
