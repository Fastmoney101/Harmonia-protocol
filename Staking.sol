// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

interface IHMO {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
}

/// @title Staking
/// @notice Staking contract for consensus nodes and indexers with slashing support
/// @dev Slashing authority is gated to a designated address (governance or multi-sig)
contract Staking {
    IHMO public immutable hmo;
    address public slashAuthority;

    struct StakeInfo {
        uint256 amount;
        uint64 sinceBlock;
    }

    mapping(address => StakeInfo) public stakes;

    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);
    event Slashed(address indexed offender, uint256 amount);
    event SlashAuthorityUpdated(address indexed oldAuthority, address indexed newAuthority);

    modifier onlySlashAuthority() {
        require(msg.sender == slashAuthority, "Staking: not slash authority");
        _;
    }

    constructor(address _hmo, address _slashAuthority) {
        require(_hmo != address(0), "Staking: zero HMO address");
        require(_slashAuthority != address(0), "Staking: zero slash authority");
        hmo = IHMO(_hmo);
        slashAuthority = _slashAuthority;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Staking: zero amount");

        StakeInfo storage s = stakes[msg.sender];
        s.amount += amount;
        s.sinceBlock = uint64(block.number);

        require(hmo.transferFrom(msg.sender, address(this), amount), "Staking: transfer failed");
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        StakeInfo storage s = stakes[msg.sender];
        require(s.amount >= amount, "Staking: insufficient stake");
        require(amount > 0, "Staking: zero amount");

        s.amount -= amount;
        require(hmo.transfer(msg.sender, amount), "Staking: transfer failed");
        emit Unstaked(msg.sender, amount);
    }

    function slash(address offender, uint256 amount) external onlySlashAuthority {
        StakeInfo storage s = stakes[offender];
        require(s.amount >= amount, "Staking: insufficient stake to slash");
        require(amount > 0, "Staking: zero slash amount");

        s.amount -= amount;
        // Slashed tokens sent to slash authority (treasury/governance)
        require(hmo.transfer(slashAuthority, amount), "Staking: slash transfer failed");
        emit Slashed(offender, amount);
    }

    function updateSlashAuthority(address newAuthority) external onlySlashAuthority {
        require(newAuthority != address(0), "Staking: zero address");
        emit SlashAuthorityUpdated(slashAuthority, newAuthority);
        slashAuthority = newAuthority;
    }

    function getStake(address staker) external view returns (uint256 amount, uint64 sinceBlock) {
        StakeInfo storage s = stakes[staker];
        return (s.amount, s.sinceBlock);
    }
}
