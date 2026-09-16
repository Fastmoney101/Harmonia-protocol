// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/HMO.sol";
import "../src/CuratorRegistry.sol";

contract CuratorRegistryTest is Test {
    HMO hmo;
    CuratorRegistry curatorRegistry;

    address curator1 = makeAddr("curator1");
    address curator2 = makeAddr("curator2");
    bytes32 subgraphId = keccak256("dex");

    function setUp() public {
        hmo = new HMO(1000 ether);
        curatorRegistry = new CuratorRegistry(address(hmo));

        hmo.transfer(curator1, 100 ether);
        hmo.transfer(curator2, 100 ether);

        vm.prank(curator1);
        hmo.approve(address(curatorRegistry), 100 ether);

        vm.prank(curator2);
        hmo.approve(address(curatorRegistry), 100 ether);
    }

    function testSignal() public {
        vm.prank(curator1);
        curatorRegistry.signal(subgraphId, 50 ether);

        assertEq(curatorRegistry.curatorSignal(subgraphId, curator1), 50 ether);
        assertEq(curatorRegistry.totalSignal(subgraphId), 50 ether);
    }

    function testMultipleCuratorsSignal() public {
        vm.prank(curator1);
        curatorRegistry.signal(subgraphId, 50 ether);

        vm.prank(curator2);
        curatorRegistry.signal(subgraphId, 30 ether);

        assertEq(curatorRegistry.totalSignal(subgraphId), 80 ether);
    }

    function testSignalAccumulates() public {
        vm.startPrank(curator1);
        curatorRegistry.signal(subgraphId, 30 ether);
        curatorRegistry.signal(subgraphId, 20 ether);
        vm.stopPrank();

        assertEq(curatorRegistry.curatorSignal(subgraphId, curator1), 50 ether);
    }

    function testUnsignal() public {
        vm.prank(curator1);
        curatorRegistry.signal(subgraphId, 50 ether);

        vm.prank(curator1);
        curatorRegistry.unsignal(subgraphId, 20 ether);

        assertEq(curatorRegistry.curatorSignal(subgraphId, curator1), 30 ether);
        assertEq(hmo.balanceOf(curator1), 70 ether);
    }

    function testUnsignalRevertsOnInsufficient() public {
        vm.prank(curator1);
        curatorRegistry.signal(subgraphId, 30 ether);

        vm.prank(curator1);
        vm.expectRevert("CuratorRegistry: insufficient signal");
        curatorRegistry.unsignal(subgraphId, 31 ether);
    }

    function testZeroAmountReverts() public {
        vm.prank(curator1);
        vm.expectRevert("CuratorRegistry: zero amount");
        curatorRegistry.signal(subgraphId, 0);
    }

    function testNoSignalReturnsZero() public view {
        assertEq(curatorRegistry.curatorSignal(subgraphId, curator1), 0);
        assertEq(curatorRegistry.totalSignal(subgraphId), 0);
    }
}
