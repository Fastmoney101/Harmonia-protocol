// SPDX-License-Identifier: Apache-2.0
// API — REST endpoints for the consensus node

use crate::dag::Event;
use crate::gossip::{handle_gossip, NodeState};
use serde::{Deserialize, Serialize};
use warp::Filter;

/// Response for transaction submission
#[derive(Serialize)]
pub struct TxResponse {
    pub status: String,
    pub event_id: String,
}

/// Response for health check
#[derive(Serialize)]
pub struct HealthResponse {
    pub status: String,
    pub node_id: String,
    pub event_count: usize,
    pub peer_count: usize,
}

/// Build the warp API filter
pub fn build_api(state: NodeState) -> impl Filter<Extract = (impl warp::Reply,), Error = warp::Rejection> + Clone {
    let submit_tx = warp::path("tx")
        .and(warp::post())
        .and(warp::body::json())
        .and(with_state(state.clone()))
        .and_then(handle_submit_tx);

    let get_events = warp::path("events")
        .and(warp::get())
        .and(with_state(state.clone()))
        .and_then(handle_get_events);

    let get_state = warp::path("state")
        .and(warp::path::param())
        .and(warp::get())
        .and(with_state(state.clone()))
        .and_then(handle_get_state);

    let gossip = warp::path("gossip")
        .and(warp::post())
        .and(warp::body::json())
        .and(with_state(state.clone()))
        .and_then(handle_gossip_endpoint);

    let health = warp::path("health")
        .and(warp::get())
        .and(with_state(state.clone()))
        .and_then(handle_health);

    submit_tx
        .or(get_events)
        .or(get_state)
        .or(gossip)
        .or(health)
}

fn with_state(state: NodeState) -> impl Filter<Extract = (NodeState,), Error = std::convert::Infallible> + Clone {
    warp::any().map(move || state.clone())
}

async fn handle_submit_tx(
    tx: serde_json::Value,
    state: NodeState,
) -> Result<impl warp::Reply, warp::Rejection> {
    let event_id = state.submit_transaction(tx);
    let response = TxResponse {
        status: "ok".to_string(),
        event_id,
    };
    Ok(warp::reply::json(&response))
}

async fn handle_get_events(state: NodeState) -> Result<impl warp::Reply, warp::Rejection> {
    let events: Vec<Event> = state.get_events();
    Ok(warp::reply::json(&events))
}

async fn handle_get_state(
    _key: String,
    state: NodeState,
) -> Result<impl warp::Reply, warp::Rejection> {
    // Placeholder: return event count as state
    let events = state.get_events();
    let response = serde_json::json!({
        "key": _key,
        "event_count": events.len(),
        "latest_events": events.iter().take(10).collect::<Vec<_>>(),
    });
    Ok(warp::reply::json(&response))
}

#[derive(Deserialize)]
struct GossipPayload {
    events: Vec<Event>,
}

async fn handle_gossip_endpoint(
    payload: GossipPayload,
    state: NodeState,
) -> Result<impl warp::Reply, warp::Rejection> {
    let our_events = handle_gossip(&state, payload.events);
    Ok(warp::reply::json(&our_events))
}

async fn handle_health(state: NodeState) -> Result<impl warp::Reply, warp::Rejection> {
    let events = state.get_events();
    let response = HealthResponse {
        status: "ok".to_string(),
        node_id: state.id,
        event_count: events.len(),
        peer_count: state.peers.len(),
    };
    Ok(warp::reply::json(&response))
}
