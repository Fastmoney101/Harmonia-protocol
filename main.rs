// SPDX-License-Identifier: Apache-2.0
// Harmonia Protocol — Consensus Node Entry Point

use harmonia_consensus::api;
use harmonia_consensus::gossip::{gossip_loop, NodeState};
use tracing_subscriber;

#[tokio::main]
async fn main() {
    // Initialize logging
    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::DEBUG)
        .init();

    // Configuration from environment
    let node_id = std::env::var("NODE_ID").unwrap_or_else(|_| "node-1".to_string());
    let listen_addr = std::env::var("NODE_LISTEN_ADDR").unwrap_or_else(|_| "0.0.0.0:9000".to_string());
    let peers: Vec<String> = std::env::var("PEERS")
        .unwrap_or_default()
        .split(',')
        .filter(|s| !s.is_empty())
        .map(|s| s.to_string())
        .collect();

    let state = NodeState::new(node_id, peers);

    // Start gossip loop in background
    tokio::spawn(gossip_loop(state.clone()));

    // Build and serve API
    let api = api::build_api(state);
    let addr: std::net::SocketAddr = listen_addr.parse().expect("Invalid listen address");

    tracing::info!("Harmonia consensus node listening on {}", addr);

    warp::serve(api).run(addr).await;
}
