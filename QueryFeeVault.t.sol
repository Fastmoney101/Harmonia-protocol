// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/HMO.sol";
import "../src/QueryFeeVault.sol";

contract QueryFeeVaultTest is Test {
    HMO hmo;
    QueryFeeVault vault;

    address payer = makeAddr("payer");
    address indexer = makeAddr("indexer");
    address curator = makeAddr("curator");
    address delegator = makeAddr("delegator");
    address treasury = makeAddr("treasury");

    bytes32 subgraphId = keccak256("dex");

    function setUp() public {
        hmo = new HMO(1000 ether);
        vault = new QueryFeeVault(address(hmo), treasury);

        hmo.transfer(payer, 100 ether);

        vm.startPrank(payer);
        hmo.approve(address(vault), 100 ether);
        vm.stopPrank();
    }

    function testFeeSplit() public {
        vm.prank(payer);
        vault.payQueryFee(subgraphId, 10 ether, indexer, curator, delegator);

        assertEq(hmo.balanceOf(indexer), 8 ether);
        assertEq(hmo.balanceOf(curator), 1 ether);
        assertEq(hmo.balanceOf(delegator), 0.5 ether);
        assertEq(hmo.balanceOf(treasury), 0.5 ether);
    }

    function testZeroAmountReverts() public {
        vm.prank(payer);
        vm.expectRevert("QueryFeeVault: zero amount");
        vault.payQueryFee(subgraphId, 0, indexer, curator, delegator);
    }

    function testZeroIndexerReverts() public {
        vm.prank(payer);
        vm.expectRevert("QueryFeeVault: zero indexer");
        vault.payQueryFee(subgraphId, 10 ether, address(0), curator, delegator);
    }

    function testInsufficientAllowanceReverts() public {
        vm.prank(payer);
        vm.expectRevert("HMO: allowance exceeded");
        vault.payQueryFee(subgraphId, 101 ether, indexer, curator, delegator);
    }
}
