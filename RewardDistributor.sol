// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "./HMO.sol";
import "./Staking.sol";
import "./IndexerRegistry.sol";
import "./CuratorRegistry.sol";

/// @title RewardDistributor
/// @notice Core tokenomics engine for epoch reward emission and distribution
/// @dev The distributor must hold HMO tokens (funded via transfer) before distributing rewards.
///      Batch distribution functions are admin-gated and intended to be called by an off-chain
///      orchestrator that computes per-participant rewards based on stake weight and uptime.
contract RewardDistributor {
    HMO public immutable hmo;
    Staking public immutable staking;
    IndexerRegistry public immutable indexerRegistry;
    CuratorRegistry public immutable curatorRegistry;

    address public treasury;
    address public admin;

    uint256 public constant EPOCH_DURATION = 1 days;
    uint256 public lastEpochTime;
    uint256 public remainingEmission;

    // Reward split percentages (in basis points, 10000 = 100%)
    uint256 public constant NODE_SHARE = 5000; // 50%
    uint256 public constant INDEXER_SHARE = 3000; // 30%
    uint256 public constant CURATOR_SHARE = 1000; // 10%
    uint256 public constant DELEGATOR_SHARE = 500; // 5%
    uint256 public constant TREASURY_SHARE = 500; // 5%

    struct EpochStats {
        uint256 totalNodeStake;
        uint256 totalIndexerStake;
        uint256 totalCuratorSignal;
        uint256 totalDelegatorStake;
    }

    EpochStats public stats;

    event EpochDistributed(
        uint256 epochReward,
        uint256 toNodes,
        uint256 toIndexers,
        uint256 toCurators,
        uint256 toDelegators,
        uint256 toTreasury
    );

    event AdminUpdated(address indexed oldAdmin, address indexed newAdmin);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event RewardsDistributed(address[] recipients, uint256[] amounts);

    modifier onlyAdmin() {
        require(msg.sender == admin, "RewardDistributor: not admin");
        _;
    }

    modifier epochReady() {
        require(block.timestamp >= lastEpochTime + EPOCH_DURATION, "RewardDistributor: epoch not ready");
        _;
    }

    constructor(
        address _hmo,
        address _staking,
        address _indexerRegistry,
        address _curatorRegistry,
        address _treasury,
        uint256 _initialEmission
    ) {
        require(_hmo != address(0), "RewardDistributor: zero HMO");
        require(_staking != address(0), "RewardDistributor: zero staking");
        require(_indexerRegistry != address(0), "RewardDistributor: zero indexer registry");
        require(_curatorRegistry != address(0), "RewardDistributor: zero curator registry");
        require(_treasury != address(0), "RewardDistributor: zero treasury");
        require(_initialEmission > 0, "RewardDistributor: zero emission");

        hmo = HMO(_hmo);
        staking = Staking(_staking);
        indexerRegistry = IndexerRegistry(_indexerRegistry);
        curatorRegistry = CuratorRegistry(_curatorRegistry);
        treasury = _treasury;
        admin = msg.sender;
        remainingEmission = _initialEmission;
        lastEpochTime = block.timestamp;
    }

    /// @notice Distribute epoch rewards. Treasury portion is sent immediately.
    ///         Node/indexer/curator/delegator portions are distributed via batch functions
    ///         by an off-chain orchestrator that computes per-participant amounts.
    function distributeEpoch() external epochReady {
        require(remainingEmission > 0, "RewardDistributor: no emission left");
        require(
            hmo.balanceOf(address(this)) >= _calculateEpochReward(),
            "RewardDistributor: insufficient HMO balance"
        );

        uint256 epochReward = _calculateEpochReward();
        remainingEmission -= epochReward;

        uint256 toNodes = (epochReward * NODE_SHARE) / 10000;
        uint256 toIndexers = (epochReward * INDEXER_SHARE) / 10000;
        uint256 toCurators = (epochReward * CURATOR_SHARE) / 10000;
        uint256 toDelegators = (epochReward * DELEGATOR_SHARE) / 10000;
        uint256 toTreasury = epochReward - toNodes - toIndexers - toCurators - toDelegators;

        // Treasury portion sent immediately
        require(hmo.transfer(treasury, toTreasury), "RewardDistributor: treasury transfer failed");

        // Remaining portions stay in contract for batch distribution
        // Distributed via distributeToNodes(), distributeToIndexers(), etc.

        emit EpochDistributed(epochReward, toNodes, toIndexers, toCurators, toDelegators, toTreasury);

        lastEpochTime = block.timestamp;
    }

    /// @notice Calculate epoch reward using linear decay approximation of exponential curve
    /// @dev E(t) = remainingEmission * e^(-k * t), approximated as 0.25% of remaining per epoch
    function _calculateEpochReward() internal view returns (uint256) {
        uint256 linearDecay = (remainingEmission * 25) / 10000; // 0.25% per epoch
        if (linearDecay < 1 ether) {
            linearDecay = 1 ether; // minimum reward floor
        }
        return linearDecay;
    }

    function calculateEpochReward() external view returns (uint256) {
        return _calculateEpochReward();
    }

    // ---------------------------
    // Batch distribution hooks (admin-gated)
    // ---------------------------

    function distributeToNodes(address[] calldata nodes, uint256[] calldata amounts) external onlyAdmin {
        require(nodes.length == amounts.length, "RewardDistributor: length mismatch");
        for (uint256 i = 0; i < nodes.length; i++) {
            require(hmo.transfer(nodes[i], amounts[i]), "RewardDistributor: node transfer failed");
        }
        emit RewardsDistributed(nodes, amounts);
    }

    function distributeToIndexers(address[] calldata indexers, uint256[] calldata amounts) external onlyAdmin {
        require(indexers.length == amounts.length, "RewardDistributor: length mismatch");
        for (uint256 i = 0; i < indexers.length; i++) {
            require(hmo.transfer(indexers[i], amounts[i]), "RewardDistributor: indexer transfer failed");
        }
        emit RewardsDistributed(indexers, amounts);
    }

    function distributeToCurators(address[] calldata curators, uint256[] calldata amounts) external onlyAdmin {
        require(curators.length == amounts.length, "RewardDistributor: length mismatch");
        for (uint256 i = 0; i < curators.length; i++) {
            require(hmo.transfer(curators[i], amounts[i]), "RewardDistributor: curator transfer failed");
        }
        emit RewardsDistributed(curators, amounts);
    }

    function distributeToDelegators(address[] calldata delegators, uint256[] calldata amounts) external onlyAdmin {
        require(delegators.length == amounts.length, "RewardDistributor: length mismatch");
        for (uint256 i = 0; i < delegators.length; i++) {
            require(hmo.transfer(delegators[i], amounts[i]), "RewardDistributor: delegator transfer failed");
        }
        emit RewardsDistributed(delegators, amounts);
    }

    // ---------------------------
    // Admin functions
    // ---------------------------

    function updateAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "RewardDistributor: zero admin");
        emit AdminUpdated(admin, newAdmin);
        admin = newAdmin;
    }

    function updateTreasury(address newTreasury) external onlyAdmin {
        require(newTreasury != address(0), "RewardDistributor: zero treasury");
        emit TreasuryUpdated(treasury, newTreasury);
        treasury = newTreasury;
    }

    /// @notice Fund the distributor with HMO tokens for reward distribution
    function fund(uint256 amount) external {
        require(amount > 0, "RewardDistributor: zero amount");
        require(hmo.transferFrom(msg.sender, address(this), amount), "RewardDistributor: fund failed");
    }
}
