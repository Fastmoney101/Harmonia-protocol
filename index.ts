import express from "express";
import { buildSchema } from "graphql";
import { graphqlHTTP } from "express-graphql";
import { Pool } from "pg";

// GraphQL schema for a Swap entity (example DEX subgraph)
const schema = buildSchema(`
  type Swap {
    id: ID!
    trader: String!
    tokenIn: String!
    tokenOut: String!
    amountIn: String!
    amountOut: String!
    timestamp: String!
  }

  type Query {
    swaps(trader: String, first: Int): [Swap!]!
    swap(id: ID!): Swap
    health: String!
  }
`);

// Database connection pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || "postgres://user:pass@localhost:5432/harmonia",
});

// Query resolvers
const root = {
  swaps: async ({ trader, first }: { trader?: string; first?: number }) => {
    const limit = Math.min(first || 100, 1000);
    const client = await pool.connect();
    try {
      const res = trader
        ? await client.query(
            "SELECT * FROM swaps WHERE trader = $1 ORDER BY timestamp DESC LIMIT $2",
            [trader, limit]
          )
        : await client.query(
            "SELECT * FROM swaps ORDER BY timestamp DESC LIMIT $1",
            [limit]
          );
      return res.rows.map((row: Record<string, unknown>) => ({
        id: row.id,
        trader: row.trader,
        tokenIn: row.token_in,
        tokenOut: row.token_out,
        amountIn: row.amount_in,
        amountOut: row.amount_out,
        timestamp: row.timestamp?.toString() ?? "",
      }));
    } finally {
      client.release();
    }
  },

  swap: async ({ id }: { id: string }) => {
    const client = await pool.connect();
    try {
      const res = await client.query("SELECT * FROM swaps WHERE id = $1", [id]);
      if (res.rows.length === 0) return null;
      const row = res.rows[0];
      return {
        id: row.id,
        trader: row.trader,
        tokenIn: row.token_in,
        tokenOut: row.token_out,
        amountIn: row.amount_in,
        amountOut: row.amount_out,
        timestamp: row.timestamp?.toString() ?? "",
      };
    } finally {
      client.release();
    }
  },

  health: () => "ok",
};

async function main() {
  const app = express();

  // GraphQL endpoint
  app.use(
    "/graphql",
    graphqlHTTP({
      schema,
      rootValue: root,
      graphiql: true,
    })
  );

  // List supported subgraphs
  app.get("/subgraphs", (_req, res) => {
    res.json({
      subgraphs: [
        { id: "example-dex", name: "Example DEX", schema: "Swap" },
      ],
    });
  });

  // Health check
  app.get("/health", (_req, res) => {
    res.json({ status: "ok", timestamp: new Date().toISOString() });
  });

  const port = parseInt(process.env.INDEXER_PORT || "4000", 10);
  app.listen(port, () => {
    console.log(`Harmonia indexer listening on http://localhost:${port}/graphql`);
  });
}

main().catch((err) => {
  console.error("Indexer failed:", err);
  process.exit(1);
});
