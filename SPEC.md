# Harmonia Protocol — Technical Specification

**Version:** 0.1.0
**Status:** Draft
**License:** Apache-2.0

---

## 1. Overview

Harmonia is a decentralized protocol that combines:

- **Hashgraph-style consensus** for high-throughput, fair ordering, and deterministic finality.
- **Indexing and query marketplace** similar to subgraph-based architectures for multi-chain and off-chain data.

This document defines the **core protocol**, **on-chain contracts**, **off-chain services**, and **network roles** in an implementation-oriented format.

## 2. Design Goals

- **High throughput & low latency**: Leaderless, gossip-based consensus with virtual voting.
- **Deterministic finality**: No forks, no probabilistic settlement.
- **Decentralized indexing**: Subgraph-like definitions and a query marketplace.
- **Multi-chain support**: Index data from multiple L1/L2 chains and off-chain sources.
- **Economic sustainability**: Single native token for security, queries, and governance.
- **AI-ready data**: Structured, verifiable, real-time data streams.

## 3. Network Roles

### 3.1 Consensus Node

- **Responsibilities:** Maintain the hashgraph DAG, participate in gossip-about-gossip, execute virtual voting to finalize events, maintain canonical ledger state.
- **Requirements:** Stake HMO, run Harmonia Consensus Node software, meet minimum hardware and uptime requirements.

### 3.2 Indexer

- **Responsibilities:** Deploy and maintain subgraphs, index on-chain and off-chain data, serve queries via the Query API, provide cryptographic query receipts.
- **Requirements:** Stake HMO in Indexer Registry, run Harmonia Indexer Node software.

### 3.3 Curator

- **Responsibilities:** Signal valuable subgraphs by staking HMO, influence query routing and rewards.

### 3.4 Delegator

- **Responsibilities:** Delegate HMO to indexers, share in indexer rewards and risks.

### 3.5 Client / AI Agent

- **Responsibilities:** Submit queries to indexers, pay for queries in HMO, optionally verify receipts and proofs.

## 4. High-Level Architecture

```
+-----------------------------+
|        Client / AI          |
+--------------+--------------+
               |
               | Query (GraphQL / gRPC / REST)
               v
+--------------+--------------+
|            Indexer          |
|  - Subgraph runtime         |
|  - Data sources (L1/L2)     |
|  - Off-chain adapters       |
+--------------+--------------+
               |
               | Transactions / Events
               v
+--------------+--------------+
|      Consensus Nodes        |
|  - Gossip-about-gossip      |
|  - Virtual voting           |
|  - Ledger state             |
+--------------+--------------+
               |
               v
+--------------+--------------+
|     On-chain Contracts      |
|  - Token (HMO)              |
|  - Staking & Slashing       |
|  - Indexer Registry         |
|  - Curator Registry         |
|  - Governance               |
+-----------------------------+
```

## 5. Consensus Layer

### 5.1 Data Structures

```text
Event {
  id: Hash
  creator: NodeId
  parents: [EventId]        // self-parent, other-parent
  timestamp: int64          // local time
  payload: [Tx]             // user transactions
  signature: bytes
  metadata: EventMetadata
}

EventMetadata {
  round: uint64
  isWitness: bool
  fame: FameStatus         // Unknown | Famous | NotFamous
  consensusTimestamp: int64? // set when finalized
}
```

### 5.2 Gossip Protocol

Gossip-about-gossip:

1. Nodes periodically select a random peer.
2. Send a batch of events plus references to parents.
3. Receiving node merges events into local DAG.

### 5.3 Virtual Voting

**Rounds:** Events are assigned to rounds based on parent rounds.

**Witnesses:** First event by a node in a round is a witness.

**Fame:** Nodes infer votes on witness fame using only DAG structure.

**Finality:** When enough famous witnesses see an event, it receives a consensus timestamp and is finalized.

### 5.4 Finality Guarantees

- Deterministic finality once consensus timestamp is assigned.
- No forks; all honest nodes converge on the same event order.

## 6. Data & Indexing Layer

### 6.1 Subgraph Definition

Subgraphs are defined declaratively (YAML + GraphQL schema):

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

### 6.2 Indexer Responsibilities

- Run subgraph runtime.
- Connect to supported chains (EVM, others) and off-chain sources (HTTP, Kafka, etc.).
- Persist indexed data in a local store (e.g., Postgres, RocksDB).
- Expose query endpoints.

### 6.3 Query API

**Baseline:** GraphQL over HTTPS

- **Endpoint:** `POST /graphql`
- **Request:** GraphQL query string, optional variables, optional `x-hmo-payment` header.
- **Response:** `data` (query result), `extensions.receipt` (signed query receipt).

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

## 7. On-Chain Contracts

Implemented in Solidity 0.8.20 with Foundry. See `contracts/src/` for source.

### 7.1 HMO Token

Standard: ERC-20-like. Functions: `transfer`, `approve`, `transferFrom`, `balanceOf`, `totalSupply`.

### 7.2 Staking & Slashing

Stake HMO for consensus nodes and indexers. Slash authority gated to governance/multi-sig.

### 7.3 Indexer Registry

Register, deactivate, and update metadata for indexer nodes.

### 7.4 Curator Registry

Signal-based curation where curators stake HMO on subgraphs.

### 7.5 Query Fee Vault

Collects and distributes query fees: 80% indexer, 10% curator, 5% delegator, 5% treasury.

### 7.6 Reward Distributor

Epoch-based reward emission with exponential decay curve and batch distribution hooks.

## 8. Economic Model

See [TOKENOMICS.md](./TOKENOMICS.md) for the full specification.

## 9. Security Model

### 9.1 Consensus

- **Assumption:** < 1/3 of consensus stake is controlled by adversaries.
- **Safety:** Finalized events cannot be reverted.
- **Liveness:** Honest nodes eventually finalize new events.

### 9.2 Indexing & Queries

- Signed query receipts.
- Optional Merkle proofs or SNARKs for data correctness (future extension).
- Slashing for provably incorrect responses.

## 10. Node Interfaces

### 10.1 Consensus Node API (gRPC/REST)

- `POST /tx` — Submit transaction.
- `GET /state/{key}` — Read state.
- `GET /events?from=...` — Stream finalized events.

### 10.2 Indexer Node API

- `POST /graphql` — Query subgraphs.
- `GET /subgraphs` — List supported subgraphs.
- `GET /health` — Health check.

## 11. Configuration & Deployment

### 11.1 Minimal config (consensus node)

```toml
[node]
id = "node-1"
listen_addr = "0.0.0.0:9000"
peers = ["node-2:9000", "node-3:9000"]

[staking]
private_key = "..."
stake_amount = "1000000000000000000"

[storage]
path = "/var/lib/harmonia/consensus"
```

### 11.2 Minimal config (indexer)

```toml
[indexer]
id = "indexer-1"
subgraphs_dir = "./subgraphs"
rpc_endpoints = ["https://mainnet.rpc", "https://l2.rpc"]

[database]
url = "postgres://user:pass@localhost:5432/harmonia"

[payments]
hmo_token_address = "0x..."
query_fee_vault = "0x..."
```

## 12. Roadmap

**Phase 1:**
- Core hashgraph consensus implementation.
- Basic HMO token + staking contracts.
- Single-chain indexing and GraphQL queries.

**Phase 2:**
- Multi-chain indexing.
- Curator and delegator flows.
- Query fee vault and receipts.

**Phase 3:**
- Advanced proofs for query correctness (Merkle/SNARK).
- Native AI-oriented query interfaces.
- On-chain governance.

## 13. Repository Structure

```
harmonia-protocol/
├── contracts/
│   ├── src/
│   │   ├── HMO.sol
│   │   ├── Staking.sol
│   │   ├── IndexerRegistry.sol
│   │   ├── CuratorRegistry.sol
│   │   ├── QueryFeeVault.sol
│   │   └── RewardDistributor.sol
│   ├── test/
│   ├── script/
│   └── foundry.toml
├── consensus/
│   ├── src/
│   └── tests/
├── indexer/
│   ├── src/
│   └── subgraphs/
├── docs/
│   ├── WHITEPAPER.md
│   ├── SPEC.md
│   ├── TOKENOMICS.md
│   └── ARCHITECTURE.md
├── docs-site/
├── .github/workflows/
└── README.md
```

## 14. Implementation Notes

**Language choices:**
- Consensus node: Rust
- Indexer: TypeScript
- Contracts: Solidity 0.8.20

**Testing:**
- Unit tests for consensus logic and DAG operations.
- Integration tests for indexing and query flows.
- Economic simulations for staking and slashing.
