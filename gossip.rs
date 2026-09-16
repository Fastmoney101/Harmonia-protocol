// SPDX-License-Identifier: Apache-2.0
// Gossip protocol — gossip-about-gossip implementation

use crate::dag::{Dag, Event};
use crate::NodeId;
use rand::seq::SliceRandom;
use std::sync::{Arc, Mutex};
use std::time::Duration;
use tracing::{debug, info};

/// Node state shared across async tasks
#[derive(Clone)]
pub struct NodeState {
    pub id: NodeId,
    pub dag: Arc<Mutex<Dag>>,
    pub peers: Vec<String>,
}

impl NodeState {
    pub fn new(id: String, peers: Vec<String>) -> Self {
        NodeState {
            id,
            dag: Arc::new(Mutex::new(Dag::new())),
            peers,
        }
    }

    /// Submit a transaction — creates a new event in the DAG
    pub fn submit_transaction(&self, tx: serde_json::Value) -> String {
        let mut dag = self.dag.lock().unwrap();

        // Get self-parent (latest event from this node)
        let parents: Vec<String> = match dag.latest_event(&self.id) {
            Some(parent) => vec![parent.id.clone()],
            None => vec![],
        };

        let event = Event::new(&self.id, parents, vec![tx.to_string()]);
        let event_id = event.id.clone();
        dag.insert(event);

        debug!("Created event {} from node {}", event_id, self.id);
        event_id
    }

    /// Get all events from the DAG
    pub fn get_events(&self) -> Vec<Event> {
        let dag = self.dag.lock().unwrap();
        dag.all_events().into_iter().cloned().collect()
    }

    /// Get events since a timestamp
    pub fn get_events_since(&self, since: i64) -> Vec<Event> {
        let dag = self.dag.lock().unwrap();
        dag.events_since(since).into_iter().cloned().collect()
    }

    /// Merge received events from a peer into the local DAG
    pub fn merge_events(&self, events: Vec<Event>) {
        let mut dag = self.dag.lock().unwrap();
        for event in events {
            if !dag.events.contains_key(&event.id) {
                let creator = event.creator.clone();
                let event_id = event.id.clone();
                dag.events.insert(event_id.clone(), event);
                dag.latest_by_node.insert(creator, event_id);
            }
        }
    }
}

/// Run the gossip loop — periodically selects a random peer and shares events
pub async fn gossip_loop(state: NodeState) {
    let interval = Duration::from_secs(3);
    let client = reqwest::Client::new();

    loop {
        tokio::time::sleep(interval).await;

        if state.peers.is_empty() {
            continue;
        }

        // Select a random peer
        let peer = state.peers.choose(&mut rand::thread_rng()).cloned();
        if let Some(peer_url) = peer {
            // Collect local events to share
            let events = state.get_events();

            if events.is_empty() {
                continue;
            }

            debug!("Gossiping {} events to peer: {}", events.len(), peer_url);

            // Send events to peer via HTTP POST /gossip
            let gossip_url = format!("{}/gossip", peer_url.trim_end_matches('/'));
            match client.post(&gossip_url).json(&events).send().await {
                Ok(resp) => {
                    if resp.status().is_success() {
                        debug!("Gossip to {} succeeded", peer_url);
                    } else {
                        debug!("Gossip to {} returned status: {}", peer_url, resp.status());
                    }
                }
                Err(e) => {
                    debug!("Gossip to {} failed: {}", peer_url, e);
                }
            }
        }
    }
}

/// Handle incoming gossip — merge received events into local DAG
pub fn handle_gossip(state: &NodeState, events: Vec<Event>) -> Vec<Event> {
    let count = events.len();
    state.merge_events(events.clone());
    info!("Merged {} events from peer", count);

    // Return our events for the peer (reciprocal gossip)
    state.get_events()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_submit_transaction() {
        let state = NodeState::new("node-1".to_string(), vec![]);

        let tx = serde_json::json!({"type": "transfer", "amount": 100});
        let event_id = state.submit_transaction(tx);

        assert!(!event_id.is_empty());

        let events = state.get_events();
        assert_eq!(events.len(), 1);
        assert_eq!(events[0].creator, "node-1");
    }

    #[test]
    fn test_multiple_transactions_link_parents() {
        let state = NodeState::new("node-1".to_string(), vec![]);

        let tx1 = serde_json::json!({"type": "tx1"});
        let tx2 = serde_json::json!({"type": "tx2"});

        let id1 = state.submit_transaction(tx1);
        let id2 = state.submit_transaction(tx2);

        let events = state.get_events();
        assert_eq!(events.len(), 2);

        // Second event should have the first as its parent
        let event2 = events.iter().find(|e| e.id == id2).unwrap();
        assert_eq!(event2.parents, vec![id1]);
    }

    #[test]
    fn test_merge_events_from_peer() {
        let state = NodeState::new("node-1".to_string(), vec![]);

        let tx = serde_json::json!({"type": "transfer", "amount": 100});
        let _ = state.submit_transaction(tx);

        // Create a peer event
        let peer_event = Event::new("node-2", vec![], vec!["peer-tx".to_string()]);

        state.merge_events(vec![peer_event]);

        let events = state.get_events();
        assert_eq!(events.len(), 2);
    }
}
