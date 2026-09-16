# Node Setup

## Consensus Node

### Prerequisites

- Rust 1.70+
- Minimum 100,000 HMO staked
- Stable internet connection
- Minimum hardware: 4 vCPUs, 8 GB RAM, 100 GB SSD

### Configuration

Create a config.toml:

```toml
[node]
id = "node-1"
listen_addr = "0.0.0.0:9000"
peers = ["http://node-2:9000", "http://node-3:9000"]

[staking]
private_key = "..."
stake_amount = "1000000000000000000"

[storage]
path = "/var/lib/harmonia/consensus"
```

### Run

```bash
cd consensus
cargo build --release
NODE_ID=node-1 NODE_LISTEN_ADDR=0.0.0.0:9000 PEERS=http://node-2:9000 cargo run --release
```

## Indexer Node

### Prerequisites

- Node.js 18+
- PostgreSQL 14+
- Minimum 10,000 HMO staked

### Configuration

Set environment variables:

```bash
INDEXER_ID=indexer-1
DATABASE_URL=postgres://user:pass@localhost:5432/harmonia
INDEXER_PORT=4000
```

### Run

```bash
cd indexer
npm install
npm run dev
```

### Register

Register your indexer on-chain:

```bash
forge cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
  $INDEXER_REGISTRY_ADDRESS "registerIndexer(string)" "ipfs://QmYourMetadata"
```
