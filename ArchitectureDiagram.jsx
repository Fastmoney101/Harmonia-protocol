import React from "react";

export default function ArchitectureDiagram() {
  return (
    <div style={{
      padding: "2rem",
      backgroundColor: "#1a1a2e",
      borderRadius: "8px",
      fontFamily: "monospace",
      color: "#a5a5a5",
      fontSize: "14px",
      lineHeight: "1.6",
      overflowX: "auto",
    }}>
      <pre style={{ margin: 0 }}>{`
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
`}</pre>
    </div>
  );
}
