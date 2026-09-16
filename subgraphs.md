# Subgraphs

Subgraphs define how to index blockchain data in Harmonia.

## Structure

A subgraph consists of:

1. **Subgraph manifest** (subgraph.yaml) — defines data sources and handlers
2. **GraphQL schema** (schema.graphql) — defines entity types
3. **Mapping functions** (mapping.ts) — event handler logic

## Example: DEX Subgraph

### subgraph.yaml

```yaml
specVersion: 0.1.0
schema:
  file: schema.graphql

dataSources:
  - kind: evm
    name: Dex
    network: mainnet
    source:
      address: "0x..."
      abi: Dex
    mapping:
      file: mapping.ts
      handlers:
        - event: Swap(indexed address,indexed address,uint256,uint256)
          handler: handleSwap
```

### schema.graphql

```graphql
type Swap @entity {
  id: ID!
  trader: Bytes!
  tokenIn: Bytes!
  tokenOut: Bytes!
  amountIn: BigInt!
  amountOut: BigInt!
  timestamp: BigInt!
}
```

## Querying

Use GraphQL to query indexed data:

```graphql
query Swaps($trader: Bytes!) {
  swaps(where: { trader: $trader }, orderBy: timestamp, orderDirection: desc, first: 100) {
    id
    tokenIn
    tokenOut
    amountIn
    amountOut
    timestamp
  }
}
```

## Curation

Curators can signal the value of a subgraph by staking HMO via the CuratorRegistry contract. Higher signal increases query routing priority and indexer rewards.
