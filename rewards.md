# Rewards

## Epoch Rewards

Rewards are distributed per epoch (24 hours).

### Distribution Split

| Recipient | % of Epoch Rewards |
|---|---|
| Consensus Nodes | 50% |
| Indexers | 30% |
| Curators | 10% |
| Delegators | 5% |
| Treasury | 5% |

## Query Fees

Each query has a cost: Fee = BaseFee + (Complexity * Rate)

- BaseFee = 0.01 HMO
- Rate = 0.0001 HMO per resolver operation

### Fee Distribution

| Recipient | % |
|---|---|
| Indexer | 80% |
| Curator | 10% |
| Delegators | 5% |
| Treasury | 5% |

## Delegation

Delegators stake HMO to indexers and earn a share of indexer rewards.

Indexers set a commission rate between 0% and 20%.

## Treasury

The treasury receives:
- 5% of epoch rewards
- 5% of query fees
- 100% of slashed tokens

Funds are used for grants, audits, infrastructure, and ecosystem growth.
