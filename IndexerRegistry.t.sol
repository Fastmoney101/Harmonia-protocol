// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/IndexerRegistry.sol";

contract IndexerRegistryTest is Test {
    IndexerRegistry registry;
    address indexer1 = makeAddr("indexer1");
    address indexer2 = makeAddr("indexer2");

    function setUp() public {
        registry = new IndexerRegistry();
    }

    function testRegisterIndexer() public {
        vm.prank(indexer1);
        registry.registerIndexer("ipfs://QmHash1");

        (bool active, uint256 stakedAmount, string memory metadataURI) = registry.getIndexer(indexer1);
        assertTrue(active);
        assertEq(stakedAmount, 0);
        assertEq(metadataURI, "ipfs://QmHash1");
    }

    function testDoubleRegisterReverts() public {
        vm.startPrank(indexer1);
        registry.registerIndexer("ipfs://QmHash1");

        vm.expectRevert("IndexerRegistry: already registered");
        registry.registerIndexer("ipfs://QmHash2");
        vm.stopPrank();
    }

    function testDeactivateIndexer() public {
        vm.prank(indexer1);
        registry.registerIndexer("ipfs://QmHash1");

        vm.prank(indexer1);
        registry.deactivateIndexer();

        (bool active,,) = registry.getIndexer(indexer1);
        assertFalse(active);
    }

    function testDeactivateNotActiveReverts() public {
        vm.prank(indexer1);
        vm.expectRevert("IndexerRegistry: not active");
        registry.deactivateIndexer();
    }

    function testUpdateMetadata() public {
        vm.startPrank(indexer1);
        registry.registerIndexer("ipfs://QmHash1");
        registry.updateMetadata("ipfs://QmHash2");
        vm.stopPrank();

        (,, string memory metadataURI) = registry.getIndexer(indexer1);
        assertEq(metadataURI, "ipfs://QmHash2");
    }

    function testGetIndexerCount() public {
        vm.prank(indexer1);
        registry.registerIndexer("ipfs://QmHash1");

        vm.prank(indexer2);
        registry.registerIndexer("ipfs://QmHash2");

        assertEq(registry.getIndexerCount(), 2);
    }
}
