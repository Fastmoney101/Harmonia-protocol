// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/HMO.sol";

contract HMOTest is Test {
    HMO hmo;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        hmo = new HMO(1000 ether);
    }

    function testInitialMint() public view {
        assertEq(hmo.totalSupply(), 1000 ether);
        assertEq(hmo.balanceOf(address(this)), 1000 ether);
    }

    function testTransfer() public {
        hmo.transfer(alice, 100 ether);
        assertEq(hmo.balanceOf(alice), 100 ether);
        assertEq(hmo.balanceOf(address(this)), 900 ether);
    }

    function testTransferRevertsOnZeroAddress() public {
        vm.expectRevert("HMO: transfer to zero address");
        hmo.transfer(address(0), 100 ether);
    }

    function testTransferRevertsOnInsufficientBalance() public {
        vm.expectRevert("HMO: insufficient balance");
        hmo.transfer(alice, 1001 ether);
    }

    function testTransferFrom() public {
        hmo.transfer(alice, 100 ether);
        vm.prank(alice);
        hmo.approve(address(this), 50 ether);

        hmo.transferFrom(alice, bob, 50 ether);
        assertEq(hmo.balanceOf(alice), 50 ether);
        assertEq(hmo.balanceOf(bob), 50 ether);
    }

    function testTransferFromRevertsOnAllowanceExceeded() public {
        hmo.transfer(alice, 100 ether);
        vm.prank(alice);
        hmo.approve(address(this), 50 ether);

        vm.expectRevert("HMO: allowance exceeded");
        hmo.transferFrom(alice, bob, 51 ether);
    }

    function testApproveAndAllowance() public {
        hmo.approve(alice, 100 ether);
        assertEq(hmo.allowance(address(this), alice), 100 ether);
    }

    function testZeroSupplyReverts() public {
        vm.expectRevert("HMO: zero supply");
        new HMO(0);
    }
}
