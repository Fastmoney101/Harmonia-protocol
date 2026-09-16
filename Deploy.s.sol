// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HMO.sol";
import "../src/Staking.sol";
import "../src/IndexerRegistry.sol";
import "../src/CuratorRegistry.sol";
import "../src/QueryFeeVault.sol";
import "../src/RewardDistributor.sol";

/// @title Deploy
/// @notice Deploys all Harmonia contracts in correct dependency order
contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy HMO token with 1B supply
        HMO hmo = new HMO(1_000_000_000 ether);
        console.log("HMO deployed:", address(hmo));

        // Deploy Staking with deployer as initial slash authority
        Staking staking = new Staking(address(hmo), msg.sender);
        console.log("Staking deployed:", address(staking));

        // Deploy IndexerRegistry
        IndexerRegistry indexerRegistry = new IndexerRegistry();
        console.log("IndexerRegistry deployed:", address(indexerRegistry));

        // Deploy CuratorRegistry
        CuratorRegistry curatorRegistry = new CuratorRegistry(address(hmo));
        console.log("CuratorRegistry deployed:", address(curatorRegistry));

        // Deploy QueryFeeVault with deployer as treasury
        QueryFeeVault vault = new QueryFeeVault(address(hmo), msg.sender);
        console.log("QueryFeeVault deployed:", address(vault));

        // Deploy RewardDistributor with 200M emission pool
        RewardDistributor distributor = new RewardDistributor(
            address(hmo),
            address(staking),
            address(indexerRegistry),
            address(curatorRegistry),
            msg.sender, // treasury
            200_000_000 ether
        );
        console.log("RewardDistributor deployed:", address(distributor));

        // Fund the distributor with HMO tokens
        hmo.transfer(address(distributor), 200_000_000 ether);
        console.log("RewardDistributor funded with 200M HMO");

        vm.stopBroadcast();
    }
}
