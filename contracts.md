# Smart Contracts

Harmonia contracts are written in Solidity 0.8.20 and managed with Foundry.

## Contracts

| Contract | File | Description |
|---|---|---|
| HMO Token | HMO.sol | Native ERC-20-like token |
| Staking | Staking.sol | Staking with slashing support |
| IndexerRegistry | IndexerRegistry.sol | Indexer registration and metadata |
| CuratorRegistry | CuratorRegistry.sol | Signal-based curation |
| QueryFeeVault | QueryFeeVault.sol | Query fee collection and distribution |
| RewardDistributor | RewardDistributor.sol | Epoch reward emission engine |

## Build

```bash
cd contracts
forge install
forge build
```

## Test

```bash
forge test --gas-report
```

## Deploy

```bash
forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast --private-key $PRIVATE_KEY
```

## Contract Architecture

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

## RewardDistributor

The RewardDistributor is the core tokenomics engine. It:

1. Must be funded with HMO tokens before distributing
2. Distributes epoch rewards using exponential decay emission
3. Sends treasury portion immediately
4. Distributes node/indexer/curator/delegator portions via admin-gated batch functions
