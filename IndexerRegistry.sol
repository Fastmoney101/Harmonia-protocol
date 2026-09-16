// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

/// @title IndexerRegistry
/// @notice Registry for indexer nodes in the Harmonia network
/// @dev Indexers register with metadata URI pointing to off-chain info (e.g., IPFS)
contract IndexerRegistry {
    struct Indexer {
        bool active;
        uint256 stakedAmount;
        string metadataURI;
    }

    mapping(address => Indexer) public indexers;
    address[] public indexerList;

    event IndexerRegistered(address indexed indexer, string metadataURI);
    event IndexerDeactivated(address indexed indexer);
    event MetadataUpdated(address indexed indexer, string metadataURI);

    function registerIndexer(string calldata metadataURI) external {
        Indexer storage idx = indexers[msg.sender];
        require(!idx.active, "IndexerRegistry: already registered");

        idx.active = true;
        idx.metadataURI = metadataURI;
        indexerList.push(msg.sender);

        emit IndexerRegistered(msg.sender, metadataURI);
    }

    function deactivateIndexer() external {
        Indexer storage idx = indexers[msg.sender];
        require(idx.active, "IndexerRegistry: not active");

        idx.active = false;
        emit IndexerDeactivated(msg.sender);
    }

    function updateMetadata(string calldata metadataURI) external {
        Indexer storage idx = indexers[msg.sender];
        require(idx.active, "IndexerRegistry: not active");

        idx.metadataURI = metadataURI;
        emit MetadataUpdated(msg.sender, metadataURI);
    }

    function getIndexer(address account) external view returns (bool active, uint256 stakedAmount, string memory metadataURI) {
        Indexer storage idx = indexers[account];
        return (idx.active, idx.stakedAmount, idx.metadataURI);
    }

    function getIndexerCount() external view returns (uint256) {
        return indexerList.length;
    }
}
