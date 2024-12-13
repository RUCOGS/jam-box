use std::collections::{HashMap, HashSet};

use bytebuffer::ByteBuffer;
use log::info;
use rand::{
    distributions::{Alphanumeric, DistString},
    rngs::StdRng,
    SeedableRng,
};
use thiserror::Error;

use crate::{
    client::{Client, ClientError, ClientID, QueuedPacket},
    packet::PacketID,
    utils::{ByteBufferExt, ByteBufferExtError},
};

#[derive(Error, Debug)]
pub enum RoomManagerError {
    #[error("problem with client {0}")]
    ClientError(ClientError),
    #[error("missing client id: {0}")]
    MissingClient(ClientID),
    #[error("unhandled packet id: {0:?}")]
    UnhandledPacketID(PacketID),
    #[error("byte buffer error: {0}")]
    ByteBufferError(ByteBufferExtError),
}

impl From<ByteBufferExtError> for RoomManagerError {
    fn from(value: ByteBufferExtError) -> Self {
        RoomManagerError::ByteBufferError(value)
    }
}

impl From<ClientError> for RoomManagerError {
    fn from(value: ClientError) -> Self {
        RoomManagerError::ClientError(value)
    }
}

// RoomID is unique for a room, and is also the string users use to access a room.
pub type RoomID = String;

/// A group of clients who are playing a game together
pub struct Room {
    pub id: RoomID,
    pub owner: ClientID,
    pub players: HashSet<ClientID>,
}

impl Room {
    pub fn new(id: RoomID, owner: ClientID) -> Self {
        Self {
            id,
            owner,
            players: HashSet::new(),
        }
    }
}

/// Manages a server's ongoing games
pub struct RoomManager {
    pub next_client_id: ClientID,
    pub rooms: HashMap<RoomID, Room>,
    pub clients: HashMap<ClientID, Client>,
    pub rng: StdRng, // TODO make this seeded
}

impl Default for RoomManager {
    fn default() -> Self {
        Self {
            clients: HashMap::new(),
            next_client_id: 0,
            rooms: HashMap::new(),
            rng: StdRng::from_entropy(),
        }
    }
}

impl RoomManager {
    pub fn new(rng: StdRng) -> Self {
        Self {
            rng,
            ..Default::default()
        }
    }

    /// Called whenever a client connects to the server
    pub fn on_client_connected(&mut self, client: Client) -> ClientID {
        let client_id = self.next_client_id;
        self.clients.insert(client_id, client);
        self.next_client_id += 1;
        return client_id;
    }

    /// Called whenever a client disconnects from the server
    pub async fn on_client_disconnected(
        &mut self,
        client_id: ClientID,
    ) -> Result<(), RoomManagerError> {
        if let Some(client) = self.clients.remove(&client_id) {
            // If client is in a room, we must notify room host that the client
            // has just disconnected
            if let Some(room_id) = &client.room_id {
                if let Some(room) = self.rooms.get(room_id) {
                    if let Some(host) = self.clients.get_mut(&room.owner) {
                        host.send_room_player_disconnected(client_id).await?;
                    }
                }
            }
        }
        Ok(())
    }

    /// Proceses the packet for a specific client.
    pub async fn process_packet(
        &mut self,
        client_id: ClientID,
        mut packet: QueuedPacket,
    ) -> Result<(), RoomManagerError> {
        info!("Client {} -> Packet {:?}", client_id, packet.packet_id);
        let client = self
            .clients
            .get_mut(&client_id)
            .ok_or(RoomManagerError::MissingClient(client_id))?;
        let p_buffer = &mut packet.buffer;

        match packet.packet_id {
            PacketID::HostRoom => {
                // Create room with a random game code, and make the client a host using that game code
                let mut room_id = Alphanumeric.sample_string(&mut self.rng, 6);
                while self.rooms.contains_key(&room_id) {
                    room_id = Alphanumeric.sample_string(&mut self.rng, 6);
                }
                let room = Room::new(room_id.clone(), client.id);
                client.room_id = Some(room_id.clone());
                self.rooms.insert(room_id.clone(), room);

                client.send_host_game_result(room_id).await?;
            }
            PacketID::HostEndRoom => {
                // Remove room and disconnect clients
                if let Some(room_id) = &client.room_id {
                    if let Some(room) = self.rooms.remove(room_id.as_str()) {
                        for client_id in room.players.iter() {
                            if let Some(mut client) = self.clients.remove(client_id) {
                                client.disconnect().await?;
                            }
                        }
                    } else {
                        client
                            .send_client_request_error("Failed to end game, room does not exist.")
                            .await?;
                    }
                } else {
                    client
                        .send_client_request_error("Failed to end game, client not in room.")
                        .await?;
                }
            }
            PacketID::JoinRoom => {
                // Add player to room
                if client.room_id.is_some() {
                    client
                        .send_client_request_error("Client already in room.")
                        .await?;
                    return Ok(());
                }
                let room_id = p_buffer.read_str_u32_len()?;
                if let Some(room) = self.rooms.get_mut(&room_id) {
                    room.players.insert(client_id);
                    client.room_id = Some(room_id);
                    client.send_join_game_result().await?;

                    if let Some(host) = self.clients.get_mut(&room.owner) {
                        host.send_room_player_connected(client_id).await?;
                    }
                } else {
                    client
                        .send_client_request_error("Room does not exist.")
                        .await?;
                }
            }
            PacketID::ServerRelayData => {
                // Relay data from client to clients
                //  - Host sends data to all connected players
                //  - Player sends data to host
                if let Some(room_id) = &client.room_id {
                    if let Some(room) = self.rooms.get(room_id) {
                        if room.owner == client.id {
                            // We are the host, forward data to all clients
                            for client_id in room.players.iter() {
                                if let Some(client) = self.clients.get_mut(client_id) {
                                    client.send_client_relay_data(packet.buffer.clone()).await?;
                                }
                            }
                        } else {
                            // We are a player, forward data to the host
                            if let Some(host) = self.clients.get_mut(&room.owner) {
                                host.send_client_relay_data(packet.buffer).await?;
                            }
                        }
                    } else {
                        client
                            .send_client_request_error("Client room does not exist.")
                            .await?;
                    }
                } else {
                    client
                        .send_client_request_error("Client is not in a room.")
                        .await?;
                }
            }
            _ => return Err(RoomManagerError::UnhandledPacketID(packet.packet_id)),
        }
        Ok(())
    }
}
