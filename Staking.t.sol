// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/HMO.sol";
import "../src/Staking.sol";

contract StakingTest is Test {
    HMO hmo;
    Staking staking;
    address slashAuthority = makeAddr("slashAuthority");
    address alice = makeAddr("alice");

    function setUp() public {
        hmo = new HMO(1000 ether);
        staking = new Staking(address(hmo), slashAuthority);
        hmo.transfer(alice, 200 ether);

        vm.prank(alice);
        hmo.approve(address(staking), 200 ether);
    }

    function testStake() public {
        vm.prank(alice);
        staking.stake(100 ether);

        (uint256 amount, uint64 sinceBlock) = staking.getStake(alice);
        assertEq(amount, 100 ether);
        assertGt(sinceBlock, 0);
    }

    function testUnstake() public {
        vm.prank(alice);
        staking.stake(100 ether);

        vm.prank(alice);
        staking.unstake(50 ether);

        (uint256 amount,) = staking.getStake(alice);
        assertEq(amount, 50 ether);
    }

    function testUnstakeReturnsTokens() public {
        vm.prank(alice);
        staking.stake(100 ether);

        uint256 balanceBefore = hmo.balanceOf(alice);

        vm.prank(alice);
        staking.unstake(50 ether);

        assertEq(hmo.balanceOf(alice), balanceBefore + 50 ether);
    }

    function testStakeRevertsOnZero() public {
        vm.prank(alice);
        vm.expectRevert("Staking: zero amount");
        staking.stake(0);
    }

    function testUnstakeRevertsOnInsufficient() public {
        vm.prank(alice);
        staking.stake(50 ether);

        vm.prank(alice);
        vm.expectRevert("Staking: insufficient stake");
        staking.unstake(51 ether);
    }

    function testSlash() public {
        vm.prank(alice);
        staking.stake(100 ether);

        vm.prank(slashAuthority);
        staking.slash(alice, 20 ether);

        (uint256 amount,) = staking.getStake(alice);
        assertEq(amount, 80 ether);
        assertEq(hmo.balanceOf(slashAuthority), 20 ether);
    }

    function testSlashRevertsOnNonAuthority() public {
        vm.prank(alice);
        staking.stake(100 ether);

        vm.prank(alice);
        vm.expectRevert("Staking: not slash authority");
        staking.slash(alice, 20 ether);
    }

    function testSlashRevertsOnInsufficientStake() public {
        vm.prank(alice);
        staking.stake(50 ether);

        vm.prank(slashAuthority);
        vm.expectRevert("Staking: insufficient stake to slash");
        staking.slash(alice, 51 ether);
    }

    function testUpdateSlashAuthority() public {
        address newAuthority = makeAddr("newAuthority");

        vm.prank(slashAuthority);
        staking.updateSlashAuthority(newAuthority);

        assertEq(staking.slashAuthority(), newAuthority);
    }
}
