// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/HMO.sol";
import "../src/Staking.sol";
import "../src/IndexerRegistry.sol";
import "../src/CuratorRegistry.sol";
import "../src/RewardDistributor.sol";

contract RewardDistributorTest is Test {
    HMO hmo;
    Staking staking;
    IndexerRegistry indexerRegistry;
    CuratorRegistry curatorRegistry;
    RewardDistributor distributor;

    address treasury = makeAddr("treasury");
    address node1 = makeAddr("node1");
    address node2 = makeAddr("node2");

    uint256 constant INITIAL_EMISSION = 200_000_000 ether;

    function setUp() public {
        hmo = new HMO(1_000_000_000 ether);
        staking = new Staking(address(hmo), address(this));
        indexerRegistry = new IndexerRegistry();
        curatorRegistry = new CuratorRegistry(address(hmo));

        distributor = new RewardDistributor(
            address(hmo),
            address(staking),
            address(indexerRegistry),
            address(curatorRegistry),
            treasury,
            INITIAL_EMISSION
        );

        // Fund the distributor with HMO tokens for reward distribution
        hmo.transfer(address(distributor), INITIAL_EMISSION);
    }

    function testConstructorSetsValues() public view {
        assertEq(distributor.remainingEmission(), INITIAL_EMISSION);
        assertEq(distributor.treasury(), treasury);
        assertEq(distributor.admin(), address(this));
    }

    function testEpochNotReadyReverts() public {
        vm.expectRevert("RewardDistributor: epoch not ready");
        distributor.distributeEpoch();
    }

    function testEpochDistribution() public {
        // Warp forward 1 day + 1 second
        vm.warp(block.timestamp + 1 days + 1);

        uint256 treasuryBefore = hmo.balanceOf(treasury);

        distributor.distributeEpoch();

        // Treasury should have received 5% of epoch reward
        uint256 expectedReward = (INITIAL_EMISSION * 25) / 10000; // 0.25% of remaining
        uint256 expectedTreasuryCut = (expectedReward * 500) / 10000; // 5% of epoch reward

        assertEq(hmo.balanceOf(treasury), treasuryBefore + expectedTreasuryCut);
        assertEq(distributor.remainingEmission(), INITIAL_EMISSION - expectedReward);
    }

    function testEpochReducesRemainingEmission() public {
        vm.warp(block.timestamp + 1 days + 1);

        uint256 emissionBefore = distributor.remainingEmission();
        distributor.distributeEpoch();

        assertLt(distributor.remainingEmission(), emissionBefore);
    }

    function testDistributeToNodes() public {
        vm.warp(block.timestamp + 1 days + 1);
        distributor.distributeEpoch();

        address[] memory nodes = new address[](2);
        nodes[0] = node1;
        nodes[1] = node2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10 ether;
        amounts[1] = 20 ether;

        uint256 balanceBefore1 = hmo.balanceOf(node1);
        uint256 balanceBefore2 = hmo.balanceOf(node2);

        distributor.distributeToNodes(nodes, amounts);

        assertEq(hmo.balanceOf(node1), balanceBefore1 + 10 ether);
        assertEq(hmo.balanceOf(node2), balanceBefore2 + 20 ether);
    }

    function testDistributeToNodesRevertsOnNonAdmin() public {
        vm.prank(node1);
        vm.expectRevert("RewardDistributor: not admin");
        address[] memory nodes = new address[](1);
        nodes[0] = node1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 10 ether;
        distributor.distributeToNodes(nodes, amounts);
    }

    function testDistributeLengthMismatchReverts() public {
        vm.warp(block.timestamp + 1 days + 1);
        distributor.distributeEpoch();

        address[] memory nodes = new address[](2);
        nodes[0] = node1;
        nodes[1] = node2;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 10 ether;

        vm.expectRevert("RewardDistributor: length mismatch");
        distributor.distributeToNodes(nodes, amounts);
    }

    function testUpdateAdmin() public {
        address newAdmin = makeAddr("newAdmin");

        distributor.updateAdmin(newAdmin);

        assertEq(distributor.admin(), newAdmin);
    }

    function testUpdateAdminRevertsOnNonAdmin() public {
        vm.prank(node1);
        vm.expectRevert("RewardDistributor: not admin");
        distributor.updateAdmin(node1);
    }

    function testFundDistributor() public {
        uint256 balanceBefore = hmo.balanceOf(address(distributor));
        hmo.approve(address(distributor), 100 ether);

        distributor.fund(100 ether);

        assertEq(hmo.balanceOf(address(distributor)), balanceBefore + 100 ether);
    }

    function testInsufficientBalanceReverts() public {
        // Deploy a distributor with emission but no actual HMO tokens
        RewardDistributor unfundedDistributor = new RewardDistributor(
            address(hmo),
            address(staking),
            address(indexerRegistry),
            address(curatorRegistry),
            treasury,
            100 ether
        );

        vm.warp(block.timestamp + 1 days + 1);

        vm.expectRevert("RewardDistributor: insufficient HMO balance");
        unfundedDistributor.distributeEpoch();
    }
}
