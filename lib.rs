// SPDX-License-Identifier: Apache-2.0
// Harmonia Protocol — Consensus Node
// Hashgraph-inspired DAG with gossip-about-gossip and virtual voting

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::HashMap;

pub mod api;
pub mod dag;
pub mod gossip;

pub use dag::Dag;
pub use dag::Event;
pub use dag::EventMetadata;
pub use dag::FameStatus;

/// Unique identifier for an event (hash of its contents)
pub type EventId = String;
/// Unique identifier for a node
pub type NodeId = String;

/// Compute SHA-256 hash of input bytes, returning hex string
pub fn compute_hash(input: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(input);
    hex::encode(hasher.finalize())
}
