//! Module that contains client related structs and traits.
//!
//! Each client is represented by a [`Client`] struct, which includes ways to send and receive packets to and from the client.
use std::{
    fmt::{self, Debug},
    sync::Arc,
};

use crate::{
    packet::PacketID,
    room_manager::RoomID,
    utils::{ByteBufferExt, ByteBufferExtError},
};
use bytebuffer::ByteBuffer;
use thiserror::Error;
use tokio::sync::Mutex;

use self::network_transport::{NetworkTransport, NetworkTransportError};

pub mod network_transport;
pub mod web_socket_transport;

/// A queued packet waiting to be processed
#[derive(Debug, Clone)]
pub struct QueuedPacket {
    /// Type of packet being processed
    pub packet_id: PacketID,
    /// Byte data of the packet  
    pub buffer: ByteBuffer,
}

impl From<QueuedPacket> for Vec<u8> {
    /// Converts a QueuedPacket into a byte array
    fn from(value: QueuedPacket) -> Self {
        let mut buffer = ByteBuffer::new_little_endian();
        buffer.write_u8(value.packet_id.into());
        buffer.write_bytes(value.buffer.as_bytes());
        buffer.into_vec()
    }
}

pub type ClientID = u16;

/// Status of the client
#[derive(Debug)]
pub enum ClientStatus {
    /// Client is not connected yet or has been disconnected and is awaiting cleanup
    Disconnected,
    /// Client has connected to the server, and is awaiting action
    Connected,
}

#[derive(Error, Debug)]
pub enum ClientError {
    #[error("problem feeding client {0} packets: {1}")]
    NetworkTransportError(ClientID, NetworkTransportError),
    #[error("byte buffer ext error: {0}")]
    ByteBufferExtError(ByteBufferExtError),
}

impl From<ByteBufferExtError> for ClientError {
    fn from(value: ByteBufferExtError) -> Self {
        ClientError::ByteBufferExtError(value)
    }
}

/// A client that is connected to the server
pub struct Client {
    /// Unique ID for the client for the current client to server session.
    ///
    /// This may change if the client reconnects to the server.
    pub id: ClientID,
    /// Client's current status
    pub status: ClientStatus,
    pub network_transport: Arc<Mutex<dyn NetworkTransport>>,
    /// Set to the room that the client is in
    pub room_id: Option<RoomID>,
    pub username: String,
}

impl Debug for Client {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        #[allow(dead_code)]
        #[derive(Debug)]
        struct Client<'a> {
            id: &'a ClientID,
            status: &'a ClientStatus,
            room_id: &'a Option<RoomID>,
            username: &'a String,
        }

        let Self {
            id,
            status,
            network_transport: _,
            room_id,
            username,
        } = self;

        fmt::Debug::fmt(
            &Client {
                id,
                status,
                room_id,
                username,
            },
            f,
        )
    }
}

impl Client {
    /// Creates a new client.
    ///
    /// Clients are associated with a network_tranport,  which is a channel that connects the client to the server.
    pub fn new(network_transport: Arc<Mutex<dyn NetworkTransport>>) -> Self {
        Self {
            id: 0,
            status: ClientStatus::Disconnected,
            network_transport,
            room_id: None,
            username: "".to_string(),
        }
    }

    /// Feeds client packets into the [`network_transport`] and then flushes the [`network_transport`]
    ///
    /// Used to immediately send a packet to the client.
    ///
    /// # Example
    ///
    /// ```rust
    /// print("hi");
    /// ````
    pub async fn feed_and_flush_packet(&mut self, packet: QueuedPacket) -> Result<(), ClientError> {
        let mut network_transport = self.network_transport.lock().await;
        network_transport
            .feed_and_flush_packet(packet)
            .await
            .map_err(|e| ClientError::NetworkTransportError(self.id, e))
    }

    /// Feeds client packets into the [`network_transport`] and then flushes the [`network_transport`].
    ///
    /// Used to immediately send packets to the client.
    pub async fn feed_and_flush_packets(
        &mut self,
        packet_queue: Vec<QueuedPacket>,
    ) -> Result<(), ClientError> {
        let mut network_transport = self.network_transport.lock().await;
        network_transport
            .feed_and_flush_packets(packet_queue)
            .await
            .map_err(|e| ClientError::NetworkTransportError(self.id, e))
    }

    /// Feeds a client packet into the [`network_transport`] and then flushes the [`network_transport`].
    ///
    /// Used to queue up packets to be sent to the client.
    pub async fn feed_packet(&mut self, packet: QueuedPacket) -> Result<(), ClientError> {
        let mut network_transport = self.network_transport.lock().await;
        network_transport
            .feed_client_packet(packet)
            .await
            .map_err(|e| ClientError::NetworkTransportError(self.id, e))
    }

    /// Feeds client packets into the [`network_transport`]
    ///
    /// Used to queue up packets to be sent to the client.
    pub async fn feed_packets(
        &mut self,
        packet_queue: Vec<QueuedPacket>,
    ) -> Result<(), ClientError> {
        let mut network_transport = self.network_transport.lock().await;
        network_transport
            .feed_client_packets(packet_queue)
            .await
            .map_err(|e| ClientError::NetworkTransportError(self.id, e))
    }

    /// Flushes the [`network_transport`].
    ///
    /// Any packets queued up using [`feed_client_packets`] or [`feed_client_packet`] will be sent to the client will be sent immediately.
    pub async fn flush_packets(&mut self) -> Result<(), ClientError> {
        let mut network_transport = self.network_transport.lock().await;
        network_transport
            .flush_client_packets()
            .await
            .map_err(|e| ClientError::NetworkTransportError(self.id, e))
    }

    /// Disconnects the [`network_transport`].
    pub async fn disconnect(&mut self) -> Result<(), ClientError> {
        let mut network_transport = self.network_transport.lock().await;
        network_transport
            .disconnect()
            .await
            .map_err(|e| ClientError::NetworkTransportError(self.id, e))
    }

    /// Sends a [`PackedID::ClientRequestError`] packet.
    pub async fn send_client_request_error(&mut self, message: &str) -> Result<(), ClientError> {
        let mut buffer = ByteBuffer::new_little_endian();
        buffer.write_str_u32_len(message)?;
        self.feed_and_flush_packet(QueuedPacket {
            packet_id: PacketID::ClientRequestError,
            buffer,
        })
        .await?;
        Ok(())
    }

    /// Sends a [`PackedID::HostGameResult`] packet.
    pub async fn send_host_game_result(&mut self, room_id: RoomID) -> Result<(), ClientError> {
        let mut buffer = ByteBuffer::new_little_endian();
        buffer.write_str_u32_len(&room_id)?;
        self.feed_and_flush_packet(QueuedPacket {
            packet_id: PacketID::HostRoomResult,
            buffer,
        })
        .await?;
        Ok(())
    }

    /// Sends a [`PacketID::JoinGameResult`] packet. This tells the client it can start sending
    /// and receiving data down its stream.
    pub async fn send_join_game_result(&mut self) -> Result<(), ClientError> {
        self.feed_and_flush_packet(QueuedPacket {
            packet_id: PacketID::JoinRoomResult,
            buffer: ByteBuffer::new(),
        })
        .await?;
        Ok(())
    }

    /// Sends a [`PacketID::ClientRelayData`] packet.
    /// This packet contains data forwarded from a [`PacketID::ServerRelayData`] packet received from another client.
    pub async fn send_client_relay_data(
        &mut self,
        sender_id: ClientID,
        bytes: &Vec<u8>,
    ) -> Result<(), ClientError> {
        let mut new_buffer = ByteBuffer::new_little_endian();
        new_buffer.write_u16(sender_id);
        new_buffer.write_bytes(bytes);
        self.feed_and_flush_packet(QueuedPacket {
            packet_id: PacketID::ClientRelayData,
            buffer: new_buffer,
        })
        .await?;
        Ok(())
    }

    pub async fn send_room_player_connected(
        &mut self,
        client_id: ClientID,
        username: &str,
    ) -> Result<(), ClientError> {
        let mut buffer = ByteBuffer::new_little_endian();
        buffer.write_u16(client_id);
        buffer.write_str_u32_len(username)?;
        self.feed_and_flush_packet(QueuedPacket {
            packet_id: PacketID::RoomPlayerConnected,
            buffer,
        })
        .await?;
        Ok(())
    }

    pub async fn send_room_player_disconnected(
        &mut self,
        client_id: ClientID,
    ) -> Result<(), ClientError> {
        let mut buffer = ByteBuffer::new_little_endian();
        buffer.write_u16(client_id);
        self.feed_and_flush_packet(QueuedPacket {
            packet_id: PacketID::RoomPlayerDisconnected,
            buffer,
        })
        .await?;
        Ok(())
    }
}
