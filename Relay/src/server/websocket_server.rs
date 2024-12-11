use std::{error::Error, sync::Arc};

use async_trait::async_trait;
use log::*;
use tokio::{net::TcpListener, sync::Mutex};

use crate::{
    client::{
        network_transport::NetworkTransportRunner, web_socket_transport::WebSocketTransport,
        Client, ClientID,
    },
    room_manager::RoomManager,
};

use super::Server;

/// Configuration data for a [`RelayServer`]`
pub struct WebSocketServerConfig {
    /// Logging level of the server
    pub log_level: log::LevelFilter,
    /// Address the server will be hosted on
    pub address: String,
}

impl Default for WebSocketServerConfig {
    fn default() -> Self {
        Self {
            log_level: log::LevelFilter::Debug,
            address: "127.0.0.1:9955".to_string(),
        }
    }
}

/// Manages incoming connections and forwarding them to a nested GamesManager
pub struct WebSocketServer {
    pub config: WebSocketServerConfig,
    pub listener: Option<TcpListener>,
    pub games_manager: Arc<Mutex<RoomManager>>,
}

impl Default for WebSocketServer {
    fn default() -> Self {
        Self::new(WebSocketServerConfig::default())
    }
}

impl WebSocketServer {
    pub fn new(config: WebSocketServerConfig) -> Self {
        env_logger::builder().filter_level(config.log_level).init();

        let games_manager = Arc::new(Mutex::new(RoomManager::default()));

        Self {
            config,
            games_manager,
            listener: None,
        }
    }
}

#[async_trait]
impl Server for WebSocketServer {
    async fn start(&mut self) {
        let try_socket = TcpListener::bind(&self.config.address).await;
        self.listener = Some(try_socket.expect("Failed to bind listener"));
        info!("Server listening on: {}", &self.config.address);

        while let Ok((stream, _)) = self.listener.as_ref().unwrap().accept().await {
            let result: Result<(), Box<dyn Error>> = async {
                let web_socket_transport =
                    Arc::new(Mutex::new(WebSocketTransport::from_stream(stream).await?));
                let client = Client::new(web_socket_transport.clone());

                let mut games_manager = self.games_manager.lock().await;
                let client_id = games_manager.connect_client(client);

                tokio::spawn(start_transport_process(
                    self.games_manager.clone(),
                    client_id,
                    web_socket_transport,
                ));

                Ok(())
            }
            .await;
            if let Err(e) = result {
                error!("Error connecting with client: {}", e);
            }
        }
    }
}

async fn start_transport_process(
    games_manager: Arc<Mutex<RoomManager>>,
    client_id: ClientID,
    web_socket_transport: Arc<Mutex<WebSocketTransport>>,
) {
    if let Err(e) = WebSocketTransport::start_transport_process(
        |packet| async {
            let mut games_manager = games_manager.lock().await;
            games_manager.process_packet(client_id, packet).await;
        },
        web_socket_transport,
    )
    .await
    {
        error!("Client {} websocket error: {}", client_id, e);
    }
    let mut games_manager = games_manager.lock().await;
    let _ = games_manager.disconnect_client(client_id).await;
}
