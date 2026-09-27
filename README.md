# Harmonia Protocol

A hybrid decentralized protocol combining hashgraph-style consensus with decentralized indexing and query markets.

## Overview

Harmonia merges two paradigms into a single network:

1. **Hashgraph-style consensus** — high-throughput, leaderless, aBFT consensus with deterministic finality (inspired by Hedera Hashgraph).
2. **Decentralized indexing** — subgraph-based indexing with a query marketplace for multi-chain and off-chain data (inspired by The Graph).

The result is a unified protocol providing:
- High-speed, leaderless consensus
- Trustless, decentralized indexing
- Market-driven query services
- Enterprise-grade governance
- AI-ready real-time data streams

## Repository Structure

```
harmonia-protocol/
├── contracts/          # Solidity smart contracts (Foundry suite)
│   ├── src/             # Contract source files
│   ├── test/            # Foundry tests
│   ├── script/          # Deployment & epoch scripts
│   └── foundry.toml     # Foundry configuration
├── consensus/          # Rust consensus node
│   ├── src/             # Gossip, DAG, virtual voting
│   └── tests/           # Integration tests
├── indexer/            # TypeScript indexer node
│   ├── src/             # Ingestion, mappings, GraphQL API
│   └── subgraphs/       # Example subgraph definitions
├── docs/               # Whitepaper, specs, tokenomics, architecture
├── docs-site/          # Docusaurus documentation site
├── .github/workflows/  # CI/CD pipeline
├── README.md
├── LICENSE
└── .env.example
```

## Smart Contracts

All contracts are written in Solidity 0.8.20 and managed with Foundry.

| Contract | Description |
|---|---|
| `HMO.sol` | Native ERC-20-like token (Harmonia Token) |
| `Staking.sol` | Staking with slashing support for consensus nodes and indexers |
| `IndexerRegistry.sol` | Registry for indexer nodes |
| `CuratorRegistry.sol` | Signal-based curation with HMO staking |
| `QueryFeeVault.sol` | Query fee collection and distribution (80/10/5/5 split) |
| `RewardDistributor.sol` | Epoch reward emission and distribution engine |

### Build & Test

```bash
cd contracts
forge install
forge build
forge test --gas-report
```

### Deploy

```bash
# Local deployment
forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast

# Distribute epoch rewards
forge script script/DistributeEpoch.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
```

## Consensus Node (Rust)

A hashgraph-inspired consensus node with gossip-about-gossip, virtual voting, and a REST/gRPC API.

```bash
cd consensus
cargo build --release
NODE_ID=node-1 PEERS=node-2:9000,node-3:9000 cargo run --release
```

### API Endpoints

- `POST /tx` — Submit a transaction
- `GET /events` — Stream finalized events
- `GET /state/{key}` — Read ledger state

## Indexer Node (TypeScript)

A subgraph-based indexer with a GraphQL query API and PostgreSQL storage.

```bash
cd indexer
npm install
npm run dev
```

### API Endpoints

- `POST /graphql` — Query subgraphs (GraphQL)
- `GET /subgraphs` — List supported subgraphs
- `GET /health` — Health check

## Tokenomics

- **Token:** HMO (Harmonia Token)
- **Max Supply:** 1,000,000,000 HMO
- **Type:** Utility + Governance + Work Token
- **Consensus:** aBFT (< 1/3 malicious stake)
- **Epoch:** 24 hours
- **Emission:** Exponential decay curve

See [docs/TOKENOMICS.md](docs/TOKENOMICS.md) for the full specification.

## CI/CD

The GitHub Actions pipeline runs on every push to `main` or `dev`:
- Foundry tests with gas reports
- Slither static analysis
- Contract artifact building
- Testnet deployment (on main branch pushes)

## Documentation

- [Whitepaper](docs/WHITEPAPER.md)
- [Technical Specification](docs/SPEC.md)
- [Tokenomics](docs/TOKENOMICS.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Docusaurus Site](docs-site/)

## License

Apache-2.0
