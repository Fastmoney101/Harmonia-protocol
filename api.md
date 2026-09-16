# API Reference

## Consensus Node API

### Submit Transaction

```
POST /tx
Content-Type: application/json

{
  "type": "transfer",
  "from": "0x...",
  "to": "0x...",
  "amount": "1000000000000000000"
}
```

Response:

```json
{
  "status": "ok",
  "event_id": "a1b2c3..."
}
```

### Get Events

```
GET /events
```

Returns all events in the DAG.

### Get State

```
GET /state/{key}
```

Read ledger state for a given key.

### Gossip Endpoint

```
POST /gossip
Content-Type: application/json

{
  "events": [...]
}
```

Receives events from a peer and returns local events (reciprocal gossip).

### Health Check

```
GET /health
```

```json
{
  "status": "ok",
  "node_id": "node-1",
  "event_count": 142,
  "peer_count": 3
}
```

## Indexer Node API

### GraphQL Query

```
POST /graphql
Content-Type: application/json

{
  "query": "{ swaps { id tokenIn tokenOut amountIn amountOut timestamp } }"
}
```

### List Subgraphs

```
GET /subgraphs
```

### Health Check

```
GET /health
```
