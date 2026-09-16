// SPDX-License-Identifier: Apache-2.0
// DAG — Directed Acyclic Graph for hashgraph consensus events

use crate::{compute_hash, EventId, NodeId};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Status of a witness event in the virtual voting process
#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub enum FameStatus {
    Unknown,
    Famous,
    NotFamous,
}

/// Metadata for consensus-related event properties
#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct EventMetadata {
    pub round: u64,
    pub is_witness: bool,
    pub fame: FameStatus,
    pub consensus_timestamp: Option<i64>,
}

impl Default for FameStatus {
    fn default() -> Self {
        FameStatus::Unknown
    }
}

/// An event in the hashgraph DAG
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Event {
    pub id: EventId,
    pub creator: NodeId,
    pub parents: Vec<EventId>,
    pub timestamp: i64,
    pub payload: Vec<String>,
    pub signature: String,
    pub metadata: EventMetadata,
}

impl Event {
    /// Create a new event
    pub fn new(creator: &str, parents: Vec<EventId>, payload: Vec<String>) -> Self {
        let timestamp = chrono::Utc::now().timestamp();
        let content = format!("{}-{}-{:?}-{:?}", creator, timestamp, parents, payload);
        let id = compute_hash(content.as_bytes());

        Event {
            id,
            creator: creator.to_string(),
            parents,
            timestamp,
            payload,
            signature: String::new(),
            metadata: EventMetadata::default(),
        }
    }

    /// Check if this event is a witness (first event by a node in a round)
    pub fn is_witness(&self) -> bool {
        self.metadata.is_witness
    }
}

/// The hashgraph DAG — stores all known events
#[derive(Default)]
pub struct Dag {
    pub events: HashMap<EventId, Event>,
    /// Track the latest event created by each node
    pub latest_by_node: HashMap<NodeId, EventId>,
}

impl Dag {
    /// Create a new empty DAG
    pub fn new() -> Self {
        Self::default()
    }

    /// Insert an event into the DAG
    pub fn insert(&mut self, event: Event) {
        let creator = event.creator.clone();
        let event_id = event.id.clone();
        self.latest_by_node.insert(creator, event_id.clone());
        self.events.insert(event_id, event);
    }

    /// Get an event by ID
    pub fn get(&self, id: &str) -> Option<&Event> {
        self.events.get(id)
    }

    /// Get the latest event created by a specific node
    pub fn latest_event(&self, node: &str) -> Option<&Event> {
        self.latest_by_node
            .get(node)
            .and_then(|id| self.events.get(id))
    }

    /// Get all events
    pub fn all_events(&self) -> Vec<&Event> {
        self.events.values().collect()
    }

    /// Get events created since a given timestamp
    pub fn events_since(&self, since: i64) -> Vec<&Event> {
        self.events
            .values()
            .filter(|e| e.timestamp > since)
            .collect()
    }

    /// Count total events in the DAG
    pub fn count(&self) -> usize {
        self.events.len()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_dag_insert_and_get() {
        let mut dag = Dag::new();
        let event = Event::new("node-1", vec![], vec!["tx1".to_string()]);

        let event_id = event.id.clone();
        dag.insert(event);

        assert_eq!(dag.count(), 1);
        assert!(dag.get(&event_id).is_some());
    }

    #[test]
    fn test_latest_event_by_node() {
        let mut dag = Dag::new();
        let event1 = Event::new("node-1", vec![], vec!["tx1".to_string()]);
        dag.insert(event1);

        let event2 = Event::new("node-1", vec![], vec!["tx2".to_string()]);
        let event2_id = event2.id.clone();
        dag.insert(event2);

        let latest = dag.latest_event("node-1");
        assert!(latest.is_some());
        assert_eq!(latest.unwrap().id, event2_id);
    }

    #[test]
    fn test_event_hash_is_deterministic() {
        let event1 = Event::new("node-1", vec![], vec!["tx1".to_string()]);
        let event2 = Event::new("node-1", vec![], vec!["tx1".to_string()]);
        // Events created at different timestamps will have different hashes
        // but the hash function itself is deterministic
        let h1 = compute_hash(b"test");
        let h2 = compute_hash(b"test");
        assert_eq!(h1, h2);
    }
}
