// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "./HMO.sol";

/// @title CuratorRegistry
/// @notice Signal-based curation where curators stake HMO to signal valuable subgraphs
/// @dev Note: Uses an array per subgraph for simplicity — not gas-scalable for high signal counts
contract CuratorRegistry {
    HMO public immutable hmo;

    struct Signal {
        uint256 amount;
        address curator;
    }

    // subgraphId => array of signals
    mapping(bytes32 => Signal[]) public signals;

    event Signaled(bytes32 indexed subgraphId, address indexed curator, uint256 amount);
    event Unsignaled(bytes32 indexed subgraphId, address indexed curator, uint256 amount);

    constructor(address _hmo) {
        require(_hmo != address(0), "CuratorRegistry: zero HMO address");
        hmo = HMO(_hmo);
    }

    function signal(bytes32 subgraphId, uint256 amount) external {
        require(amount > 0, "CuratorRegistry: zero amount");

        // Pull tokens from curator
        require(hmo.transferFrom(msg.sender, address(this), amount), "CuratorRegistry: transfer failed");

        // Add to existing signal or create new
        bool found = false;
        Signal[] storage list = signals[subgraphId];
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i].curator == msg.sender) {
                list[i].amount += amount;
                found = true;
                break;
            }
        }
        if (!found) {
            list.push(Signal(amount, msg.sender));
        }

        emit Signaled(subgraphId, msg.sender, amount);
    }

    function unsignal(bytes32 subgraphId, uint256 amount) external {
        require(amount > 0, "CuratorRegistry: zero amount");

        Signal[] storage list = signals[subgraphId];

        for (uint256 i = 0; i < list.length; i++) {
            if (list[i].curator == msg.sender && list[i].amount >= amount) {
                list[i].amount -= amount;
                require(hmo.transfer(msg.sender, amount), "CuratorRegistry: transfer failed");
                emit Unsignaled(subgraphId, msg.sender, amount);
                return;
            }
        }

        revert("CuratorRegistry: insufficient signal");
    }

    function totalSignal(bytes32 subgraphId) external view returns (uint256 total) {
        Signal[] storage list = signals[subgraphId];
        for (uint256 i = 0; i < list.length; i++) {
            total += list[i].amount;
        }
    }

    function curatorSignal(bytes32 subgraphId, address curator) external view returns (uint256) {
        Signal[] storage list = signals[subgraphId];
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i].curator == curator) {
                return list[i].amount;
            }
        }
        return 0;
    }
}
