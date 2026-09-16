# Harmonia Tokenomics Specification (HMO)

**Version:** 0.1.0
**Status:** Draft
**License:** Apache-2.0

---

## 1. Token Overview

| Property | Value |
|---|---|
| Name | Harmonia Token |
| Symbol | HMO |
| Decimals | 18 |
| Type | Utility + Governance + Work Token |
| Supply Model | Capped + Emission Curve |
| Consensus Role | Staking for Hashgraph nodes |
| Indexing Role | Staking for Indexers & Curators |
| Economic Role | Query fees, slashing, rewards |

## 2. Supply Model

### 2.1 Max Supply

```
MAX_SUPPLY = 1,000,000,000 HMO
```

### 2.2 Initial Allocation

| Category | % | Amount | Notes |
|---|---|---|---|
| Protocol Treasury | 20% | 200M | Grants, R&D, audits |
| Consensus Bootstrap | 15% | 150M | Node incentives |
| Indexer Bootstrap | 10% | 100M | Indexer rewards |
| Curator Incentives | 5% | 50M | Early curation |
| Team & Advisors | 15% | 150M | 4-year vesting |
| Community Sale | 20% | 200M | Public distribution |
| Ecosystem Fund | 15% | 150M | Partnerships |

### 2.3 Emission Curve

Harmonia uses a decreasing exponential emission curve:

\[ E(t) = E_0 \cdot e^{-k \cdot t} \]

Where:
- \( E_0 = 200,000,000 \) HMO (remaining supply)
- \( k = 0.25 \) (decay constant)
- \( t \) = years since genesis

**Emission Phases:**

| Phase | Years | Annual Inflation | Purpose |
|---|---|---|---|
| Bootstrap | 0-4 | 8-12% | Attract nodes & indexers |
| Stability | 5-10 | 3-6% | Sustain participation |
| Long-Term | 10+ | ~1% | Maintain security |

## 3. Staking Economics

### 3.1 Consensus Node Staking

```
MIN_NODE_STAKE = 100,000 HMO
```

Rewards are proportional to:
- Stake weight
- Node uptime
- Node reputation (optional future module)

### 3.2 Indexer Staking

```
MIN_INDEXER_STAKE = 10,000 HMO
```

Staking influences:
- Query routing priority
- Slashing risk
- Reward multiplier

### 3.3 Curator Staking

Curators stake HMO on subgraphs:

```
signal(subgraphId, amount)
```

Signal determines:
- Subgraph ranking
- Indexer reward weighting
- Query routing preference

## 4. Reward Distribution

Rewards are distributed per epoch (24 hours).

### 4.1 Epoch Reward Pool

\[ R_{epoch} = E(t) / 365 \]

### 4.2 Distribution Breakdown

| Recipient | % of Epoch Rewards |
|---|---|
| Consensus Nodes | 50% |
| Indexers | 30% |
| Curators | 10% |
| Delegators | 5% |
| Treasury | 5% |

## 5. Query Fee Model

### 5.1 Query Fee Formula

\[ Fee = BaseFee + (Complexity \times Rate) \]

Where:
- `BaseFee = 0.01 HMO`
- `Complexity` = measured in resolver operations
- `Rate = 0.0001 HMO` per operation

### 5.2 Fee Distribution

| Recipient | % |
|---|---|
| Indexer | 80% |
| Curator | 10% |
| Delegators | 5% |
| Treasury | 5% |

### 5.3 Query Receipts

Indexers must return:

```json
{
  "queryId": "...",
  "indexer": "0x...",
  "timestamp": "...",
  "signature": "..."
}
```

Receipts are used for verification, dispute resolution, and slashing.

## 6. Slashing Conditions

### 6.1 Consensus Node Slashing

| Condition | Penalty |
|---|---|
| Double-signing | 5-20% stake |
| Equivocation | 10% stake |
| Downtime > 24h | 1% stake |
| Malicious gossip | 20% stake |

### 6.2 Indexer Slashing

| Condition | Penalty |
|---|---|
| Incorrect query result | 1-5% stake |
| Fraudulent receipt | 10% stake |
| Subgraph manipulation | 10-30% stake |
| Extended downtime | 1% stake |

### 6.3 Curator Slashing

Curators are only slashed for:
- Proven collusion
- Manipulative signaling
- Fraudulent metadata

**Penalty:** 1-10% stake

## 7. Delegation Model

Delegators stake HMO to indexers.

**Reward Split:**

\[ DelegatorReward = IndexerReward \times (DelegatedStake / TotalStake) \]

Indexers set a commission rate:

```
commission in [0%, 20%]
```

## 8. Governance

### 8.1 Voting Power

\[ VotingPower = StakedHMO + CuratorSignal + NodeReputation \]

### 8.2 Proposal Types

- Parameter changes
- Treasury allocations
- Protocol upgrades
- Subgraph certification

### 8.3 Voting Period

```
VOTING_PERIOD = 7 days
QUORUM = 10%
PASS_THRESHOLD = 50% + 1
```

## 9. Treasury Model

Treasury receives:
- 5% of epoch rewards
- 5% of query fees
- 100% of slashed tokens

Treasury funds:
- Grants
- Audits
- Infrastructure
- Ecosystem growth

## 10. Token Flow

```
        +------------------+
        |   Consensus      |
        |     Nodes        |
        +--------+---------+
                 |
                 | Rewards
                 v
+--------+  +----+----+  +-----------+
|Treasury|  |Indexers|  |Curators   |
+--------+  +----+----+  +-----------+
                 |
                 | Query Fees
                 v
            +----------+
            |Delegators|
            +----------+
```

## 11. Implementation Notes

- All reward logic is implemented in Solidity contracts (`RewardDistributor.sol`).
- Emission curve is computed off-chain and pushed via governance.
- Slashing requires multi-sig or governance approval.
- Query fees use ERC-20 transfers + off-chain receipts.
- Batch distribution functions are admin-gated and called by an off-chain orchestrator.
