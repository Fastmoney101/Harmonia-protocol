// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/RewardDistributor.sol";

/// @title DistributeEpoch
/// @notice Manually triggers epoch reward distribution
contract DistributeEpoch is Script {
    function run() external {
        address distributorAddress = vm.envAddress("REWARD_DISTRIBUTOR");

        vm.startBroadcast();

        RewardDistributor distributor = RewardDistributor(distributorAddress);
        distributor.distributeEpoch();

        console.log("Epoch distributed successfully.");

        vm.stopBroadcast();
    }
}
