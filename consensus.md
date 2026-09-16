# Consensus

Harmonia uses a Hashgraph-inspired consensus model.

## Key Mechanisms

### Gossip-about-Gossip

Nodes periodically select a random peer and share their known events. This creates rapid propagation across the network without a leader.

### Virtual Voting

Nodes infer votes on event ordering from the DAG structure itself — no explicit vote messages needed. This eliminates communication overhead while maintaining aBFT guarantees.

### aBFT Security

Asynchronous Byzantine Fault Tolerance ensures safety even if up to 1/3 of nodes (by stake) are malicious.

### Deterministic Finality

Once an event receives a consensus timestamp, it is finalized. No forks, no probabilistic settlement.

## Consensus Node Requirements

- Stake minimum 100,000 HMO
- Run Harmonia Consensus Node software (Rust)
- Meet minimum hardware and uptime requirements
- Participate in gossip protocol

## Performance

- 10,000+ TPS throughput
- Sub-second finality
- Very low energy consumption
- Leaderless (DDoS-resistant)
