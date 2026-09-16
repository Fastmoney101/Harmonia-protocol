// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "./HMO.sol";

/// @title QueryFeeVault
/// @notice Collects and distributes query fees according to the Harmonia economic model
/// @dev Fee split: 80% indexer, 10% curator, 5% delegator, 5% treasury
contract QueryFeeVault {
    HMO public immutable hmo;
    address public treasury;

    event QueryFeePaid(
        bytes32 indexed subgraphId,
        address indexed payer,
        uint256 amount,
        address indexer,
        uint256 indexerCut,
        uint256 curatorCut,
        uint256 delegatorCut,
        uint256 treasuryCut
    );

    constructor(address _hmo, address _treasury) {
        require(_hmo != address(0), "QueryFeeVault: zero HMO address");
        require(_treasury != address(0), "QueryFeeVault: zero treasury");
        hmo = HMO(_hmo);
        treasury = _treasury;
    }

    function payQueryFee(
        bytes32 subgraphId,
        uint256 amount,
        address indexer,
        address curator,
        address delegator
    ) external {
        require(amount > 0, "QueryFeeVault: zero amount");
        require(indexer != address(0), "QueryFeeVault: zero indexer");

        // Pull tokens from payer
        require(hmo.transferFrom(msg.sender, address(this), amount), "QueryFeeVault: transfer failed");

        // Calculate splits
        uint256 indexerCut = (amount * 80) / 100;
        uint256 curatorCut = (amount * 10) / 100;
        uint256 delegatorCut = (amount * 5) / 100;
        uint256 treasuryCut = amount - indexerCut - curatorCut - delegatorCut;

        // Distribute
        require(hmo.transfer(indexer, indexerCut), "QueryFeeVault: indexer transfer failed");
        require(hmo.transfer(curator, curatorCut), "QueryFeeVault: curator transfer failed");
        require(hmo.transfer(delegator, delegatorCut), "QueryFeeVault: delegator transfer failed");
        require(hmo.transfer(treasury, treasuryCut), "QueryFeeVault: treasury transfer failed");

        emit QueryFeePaid(
            subgraphId,
            msg.sender,
            amount,
            indexer,
            indexerCut,
            curatorCut,
            delegatorCut,
            treasuryCut
        );
    }

    function updateTreasury(address newTreasury) external {
        require(msg.sender == treasury, "QueryFeeVault: not treasury");
        require(newTreasury != address(0), "QueryFeeVault: zero treasury");
        treasury = newTreasury;
    }
}
