# Harmonia Protocol — Architecture

## Overview

Harmonia is a two-layer protocol:

1. **Consensus Layer** — Hashgraph-inspired DAG with gossip-about-gossip and virtual voting
2. **Data Layer** — Subgraph-based indexing with a query marketplace

## Layer 1: Consensus

### Hashgraph DAG

The consensus layer uses a Directed Acyclic Graph (DAG) of events. Each event contains:

- Transaction payload
- References to parent events (self-parent + other-parent)
- Creator's signature
- Consensus metadata (round, witness status, fame, consensus timestamp)

### Gossip-about-Gossip

Nodes periodically select a random peer and share their known events. This creates a rapidly propagating mesh where all nodes eventually receive all events.

### Virtual Voting

Instead of sending explicit vote messages, nodes infer votes from the DAG structure itself. This eliminates the communication overhead of traditional consensus protocols while maintaining aBFT guarantees.

### Finality

When a sufficient number of "famous witnesses" (special events determined by the virtual voting process) see an event, that event receives a consensus timestamp and is considered finalized. This finality is deterministic — no forks are possible.

## Layer 2: Indexing

### Subgraphs

Subgraphs are declarative definitions of how to index blockchain data. They specify:

- Data sources (smart contract addresses, ABIs)
- Event handlers (mapping functions)
- Entity schemas (GraphQL types)

### Indexer Runtime

The indexer node:

1. Connects to blockchain RPC endpoints
2. Listens for events matching subgraph definitions
3. Executes handler functions to transform events into entities
4. Stores entities in a local database (PostgreSQL)
5. Serves GraphQL queries against the stored data

### Query Marketplace

Clients pay HMO tokens for queries. The `QueryFeeVault` contract enforces the fee split:

- 80% to the indexer
- 10% to the curator
- 5% to the delegator
- 5% to the treasury

### Cryptographic Receipts

Each query response includes a signed receipt that can be used for:
- Verification of data authenticity
- Dispute resolution
- Slashing of indexers that serve incorrect data

## Token Flow

```
                    +-- Epoch Rewards --+
                    |                   |
                    v                   v
        +------------------+   +------------------+
        |   Consensus      |   |     Indexers     |
        |     Nodes (50%)  |   |      (30%)      |
        +--------+---------+   +--------+---------+
                 |                      |
                 |                      v
                 |              +-------+-------+
                 |              |  Delegators   |
                 |              |    (5%)      |
                 |              +-------+-------+
                 |                      |
                 v                      v
        +------------------+   +------------------+
        |    Treasury      |   |    Curators      |
        |     (5%)         |   |     (10%)       |
        +------------------+   +------------------+
```

## Security Model

### Consensus Security

- **Threat model:** Up to 1/3 of consensus stake controlled by adversaries
- **Safety:** Finalized events cannot be reverted
- **Liveness:** Honest nodes eventually finalize new events
- **No leader:** No single point of failure or DDoS target

### Indexing Security

- **Stake slashing:** Indexers and curators stake HMO, which can be slashed
- **Query receipts:** Cryptographic proof of query responses
- **Future:** Merkle proofs or SNARKs for data correctness verification

## Smart Contract Architecture

```
HMO (Token)
  |
  +-- Staking (stake/unstake/slash)
  |
  +-- IndexerRegistry (register/deactivate/metadata)
  |
  +-- CuratorRegistry (signal/unsignal)
  |
  +-- QueryFeeVault (payQueryFee -> 80/10/5/5 split)
  |
  +-- RewardDistributor (distributeEpoch -> batch hooks)
```

## Deployment Architecture

```
┌─────────────────────────────────────────────────┐
│                  GitHub (CI/CD)                   │
│  ┌──────────┐  ┌──────────┐  ┌───────────────┐  │
│  │  Foundry │  │  Slither │  │  Deploy to    │  │
│  │  Tests   │  │  Analysis│  │  Testnet      │  │
│  └──────────┘  └──────────┘  └───────────────┘  │
└──────────────────────┬──────────────────────────┘
                       │
                       v
┌─────────────────────────────────────────────────┐
│               On-Chain (EVM)                      │
│  HMO | Staking | IndexerReg | CuratorReg |       │
│  QueryFeeVault | RewardDistributor               │
└─────────────────────────────────────────────────┘
                       │
                       v
┌─────────────────────────────────────────────────┐
│              Off-Chain Nodes                      │
│  ┌─────────────────┐  ┌─────────────────────┐   │
│  │  Consensus Node  │  │    Indexer Node     │   │
│  │  (Rust + warp)   │  │  (TypeScript + PG)  │   │
│  │  Gossip loop     │  │  GraphQL API        │   │
│  │  DAG storage     │  │  Subgraph runtime   │   │
│  └─────────────────┘  └─────────────────────┘   │
└─────────────────────────────────────────────────┘
```
