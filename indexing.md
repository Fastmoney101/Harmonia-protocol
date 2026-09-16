# Indexing Layer

Harmonia uses subgraphs to index blockchain data.

## Subgraphs

Subgraphs are declarative definitions that specify:

- Data sources (smart contract addresses, ABIs)
- Event handlers (mapping functions)
- Entity schemas (GraphQL types)

## Supported Data Sources

- EVM chains (Ethereum, L2s)
- Non-EVM chains (future)
- Off-chain sources (HTTP, Kafka, etc.)

## Indexer Node

Indexers run a subgraph runtime that:

1. Connects to blockchain RPC endpoints
2. Listens for events matching subgraph definitions
3. Executes handler functions to transform events into entities
4. Stores entities in a local database (PostgreSQL)
5. Serves GraphQL queries

## Query Marketplace

Clients pay HMO tokens for queries. The fee is split:

- 80% to the indexer
- 10% to the curator
- 5% to the delegator
- 5% to the treasury

Each query response includes a cryptographic receipt for verification and dispute resolution.
