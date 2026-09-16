# Getting Started

## Prerequisites

- Rust (for consensus node)
- Node.js 18+ (for indexer)
- Foundry (for contracts)
- PostgreSQL (for indexer database)

## Clone the Repository

```bash
git clone https://github.com/harmonia/harmonia-protocol.git
cd harmonia-protocol
```

## Smart Contracts

```bash
cd contracts
forge install
forge build
forge test --gas-report
```

## Consensus Node

```bash
cd consensus
cargo build --release
NODE_ID=node-1 PEERS=http://localhost:9001 cargo run --release
```

## Indexer

```bash
cd indexer
npm install
npm run dev
```

## Deploy Contracts Locally

```bash
# Start a local EVM node (e.g., anvil)
anvil

# Deploy
cd contracts
forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
```
