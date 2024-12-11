use server::{websocket_server::WebSocketServer, Server};

pub mod client;
pub mod packet;
pub mod room_manager;
pub mod server;
pub mod utils;

#[tokio::main]
async fn main() {
    let mut relay_server = WebSocketServer::default();
    relay_server.start().await;
}
