use std::collections::HashMap;

use bytebuffer::ByteBuffer;
use log::info;
use rand::{
    distributions::{Alphanumeric, DistString},
    rngs::ThreadRng,
    Rng,
};
use thiserror::Error;

use crate::{
    client::{network_transport::NetworkTransportError, Client, ClientID, QueuedPacket},
    packet::PacketID,
    utils::ByteBufferExt,
};

#[derive(Error, Debug)]
pub enum RoomManagerError {
    #[error("problem feeding client {0} packets: {1}")]
    NetworkTransportError(ClientID, NetworkTransportError),
    #[error("missing client id: {0}")]
    MissingClient(ClientID),
    #[error("unhandled packet id: {0:?}")]
    UnhandledPacketID(PacketID),
}

/// A group of clients who are playing a game together
pub struct Room {}

/// Manages a server's ongoing games
pub struct RoomManager {
    pub next_client_id: ClientID,
    pub clients: HashMap<ClientID, Client>,
    pub rng: ThreadRng, // TODO make this seeded
}

impl Default for RoomManager {
    fn default() -> Self {
        Self {
            clients: HashMap::new(),
            next_client_id: 0,
            rng: rand::thread_rng(),
        }
    }
}

impl RoomManager {
    /// Connect a client to the server
    pub fn connect_client(&mut self, client: Client) -> ClientID {
        let client_id = self.next_client_id;
        self.clients.insert(client_id, client);
        self.next_client_id += 1;
        return client_id;
    }

    /// Disconnect a client from the server
    pub async fn disconnect_client(&mut self, client_id: ClientID) -> Result<(), RoomManagerError> {
        if let Some(mut client) = self.clients.remove(&client_id) {
            client
                .feed_and_flush_packet(QueuedPacket {
                    packet_id: PacketID::ClientDisconnect,
                    buffer: ByteBuffer::new(),
                })
                .await
                .map_err(|e| RoomManagerError::NetworkTransportError(client_id, e))?;
            let mut network_transport = client.network_transport.lock().await;
            network_transport
                .disconnect()
                .await
                .map_err(|e| RoomManagerError::NetworkTransportError(client_id, e))?;
        }
        Ok(())
    }

    /// Proceses the packet for a specifict client.
    pub async fn process_packet(
        &mut self,
        client_id: ClientID,
        packet: QueuedPacket,
    ) -> Result<(), RoomManagerError> {
        info!("Client {} -> Packet {:?}", client_id, packet.packet_id);
        match packet.packet_id {
            PacketID::HostGame => {
                // Create a random game code, and make the client a host using that game code
                let client = self
                    .clients
                    .get_mut(&client_id)
                    .ok_or(RoomManagerError::MissingClient(client_id))?;
                let game_code = Alphanumeric.sample_string(&mut self.rng, 6);
                client.game_code = Some(game_code.clone());

                let mut buffer = ByteBuffer::new_little_endian();
                buffer.write_str_u32_len(&game_code);
                client.feed_and_flush_packet(QueuedPacket {
                    packet_id: PacketID::HostGameResult,
                    buffer,
                });
            }
            _ => return Err(RoomManagerError::UnhandledPacketID(packet.packet_id)),
        }
        Ok(())
    }
}
