use std::{
    collections::{HashMap, HashSet},
    io::Read,
};

use bytebuffer::ByteBuffer;
use log::info;
use rand::{
    distributions::{Alphanumeric, DistString},
    prelude::Distribution,
    rngs::StdRng,
    Rng, SeedableRng,
};
use thiserror::Error;

use crate::{
    client::{Client, ClientError, ClientID, ClientStatus, QueuedPacket},
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
    #[error("buffer io error: {0}")]
    BufferIOError(std::io::Error),
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

impl From<std::io::Error> for RoomManagerError {
    fn from(value: std::io::Error) -> Self {
        RoomManagerError::BufferIOError(value)
    }
}

// RoomID is unique for a room, and is also the string users use to access a room.
pub type RoomID = String;

/// A group of clients who are playing a game together
#[derive(Debug)]
pub struct Room {
    pub id: RoomID,
    pub owner: ClientID,
    pub players: HashSet<ClientID>,
    pub usernames: HashSet<String>,
    pub max_players: u16,
}

impl Room {
    pub fn new(id: RoomID, owner: ClientID, max_players: u16) -> Self {
        Self {
            id,
            owner,
            players: HashSet::new(),
            usernames: HashSet::new(),
            max_players,
        }
    }

    pub fn is_full(&self) -> bool {
        self.players.len() >= self.max_players as usize
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
    pub fn on_client_connected(&mut self, mut client: Client) -> ClientID {
        let client_id = self.next_client_id;
        client.id = client_id;
        client.status = ClientStatus::Connected;
        self.clients.insert(client_id, client);
        self.next_client_id += 1;
        // We reserve client_id of 0 to mean a broadcast packet
        if self.next_client_id == 0 {
            self.next_client_id = 1;
        }
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
                if let Some(room) = self.rooms.get_mut(room_id) {
                    if room.owner == client_id {
                        // If the host themselves is disconnecting, then take down the room
                        for client_id in room.players.iter() {
                            if let Some(mut client) = self.clients.remove(client_id) {
                                client.disconnect().await?;
                            }
                        }
                        self.rooms.remove(room_id);
                    } else {
                        // If we are a player, then remove ourselves from the room and
                        // notify the host that we disconnected
                        room.usernames.remove(&client.username);
                        room.players.remove(&client_id);
                        if let Some(host) = self.clients.get_mut(&room.owner) {
                            host.send_room_player_disconnected(client_id).await?;
                        }
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
        let client = self
            .clients
            .get_mut(&client_id)
            .ok_or(RoomManagerError::MissingClient(client_id))?;
        let p_buffer = &mut packet.buffer;

        match packet.packet_id {
            PacketID::HostRoom => {
                // Create room with a random game code, and make the client a host using that game code
                let max_players = p_buffer.read_u16()?;

                let mut room_id = AlphabetCaps.sample_string(&mut self.rng, 4);
                while self.rooms.contains_key(&room_id) {
                    room_id = AlphabetCaps.sample_string(&mut self.rng, 4);
                }
                let room = Room::new(room_id.clone(), client_id, max_players);
                client.room_id = Some(room_id.clone());
                self.rooms.insert(room_id.clone(), room);

                client.send_host_game_result(room_id).await?;
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
                let mut username = p_buffer.read_str_u32_len()?;
                username.truncate(12);
                if username.len() == 0 {
                    client
                        .send_client_request_error("Username cannot be blank.")
                        .await?;
                } else if let Some(room) = self.rooms.get_mut(&room_id) {
                    if room.is_full() {
                        client.send_client_request_error("Room is full.").await?;
                        return Ok(());
                    }
                    if !room.usernames.contains(&username) {
                        room.usernames.insert(username.clone());
                        room.players.insert(client_id);
                        client.room_id = Some(room_id);
                        client.username = username.clone();
                        client.send_join_game_result().await?;

                        if let Some(host) = self.clients.get_mut(&room.owner) {
                            host.send_room_player_connected(client_id, &username)
                                .await?;
                        }
                    } else {
                        client.send_client_request_error("Username taken.").await?;
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
                    let mut p_data = Vec::<u8>::new();
                    if let Some(room) = self.rooms.get(room_id) {
                        if room.owner == client_id {
                            // We are the host, we can either broadcast packet to all players or specify a specific player
                            let dest_client_id = p_buffer.read_u16()?;
                            p_buffer
                                .read_to_end(&mut p_data)
                                .expect("Expect ServerRelayData to fit in Vec<u8>.");
                            info!("host sending packet to {}", dest_client_id);
                            if dest_client_id > 0 {
                                // Send packet to specific player
                                if let Some(dest_client) = self.clients.get_mut(&dest_client_id) {
                                    dest_client
                                        .send_client_relay_data(client_id, &p_data)
                                        .await?;
                                }
                            } else {
                                // Broadcast packet to all players
                                for dest_client_id in room.players.iter() {
                                    if let Some(client) = self.clients.get_mut(dest_client_id) {
                                        client
                                            .send_client_relay_data(*dest_client_id, &p_data)
                                            .await?;
                                    }
                                }
                            }
                        } else {
                            // Read destination ID, although we ignore it for non-host players.
                            // Non-host players automatically forward data to the host
                            p_buffer.read_u16()?;
                            // We are a player, we can only forward data to the host
                            p_buffer
                                .read_to_end(&mut p_data)
                                .expect("Expect ServerRelayData to fit in Vec<u8>.");
                            if let Some(host) = self.clients.get_mut(&room.owner) {
                                host.send_client_relay_data(client_id, &p_data).await?;
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
        // info!("Rooms: {:?}", self.rooms);
        // info!("Clients: {:?}", self.clients);
        Ok(())
    }
}

/// Random distribution made of capitalized English letters.
struct AlphabetCaps;

impl Distribution<u8> for AlphabetCaps {
    fn sample<R: Rng + ?Sized>(&self, rng: &mut R) -> u8 {
        const RANGE: u32 = 26;
        const GEN_CHARSET: &[u8] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        let var = rng.next_u32() % RANGE;
        return GEN_CHARSET[var as usize];
    }
}

impl DistString for AlphabetCaps {
    fn append_string<R: Rng + ?Sized>(&self, rng: &mut R, string: &mut String, len: usize) {
        unsafe {
            let v = string.as_mut_vec();
            v.extend(self.sample_iter(rng).take(len));
        }
    }
}
