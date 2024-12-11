//! Server related traits.
//!
//! Current server implementations:
//! - [`websocket_server`] -> WebSocket server

use async_trait::async_trait;

pub mod websocket_server;

/// A server for MiniMMO
#[async_trait]
pub trait Server {
    /// Starts the server, allowing players to connect to the server.
    async fn start(&mut self);
}
