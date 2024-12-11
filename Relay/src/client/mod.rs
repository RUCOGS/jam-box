//! Module that contains client related structs and traits.
//!
//! Each client is represented by a [`Client`] struct, which includes ways to send and receive packets to and from the client.
use std::sync::Arc;

use crate::{packet::PacketID, utils::ByteBufferExt};
use bytebuffer::ByteBuffer;
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

pub type ClientID = u32;

/// Status of the client
pub enum ClientStatus {
    /// Client is not connected yet or has been disconnected and is awaiting cleanup
    Disconnected,
    /// Client has connected to the server, and is awaiting action
    Connected,
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
    pub game_code: Option<String>,
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
            game_code: None,
        }
    }

    pub fn is_host(&self) -> bool {
        return self.game_code.is_some();
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
    pub async fn feed_and_flush_packet(
        &mut self,
        packet: QueuedPacket,
    ) -> Result<(), NetworkTransportError> {
        let mut network_transport = self.network_transport.lock().await;
        network_transport.feed_and_flush_packet(packet).await
    }

    /// Feeds client packets into the [`network_transport`] and then flushes the [`network_transport`].
    ///
    /// Used to immediately send packets to the client.
    pub async fn feed_and_flush_packets(
        &mut self,
        packet_queue: Vec<QueuedPacket>,
    ) -> Result<(), NetworkTransportError> {
        let mut network_transport = self.network_transport.lock().await;
        network_transport.feed_and_flush_packets(packet_queue).await
    }

    /// Feeds a client packet into the [`network_transport`] and then flushes the [`network_transport`].
    ///
    /// Used to queue up packets to be sent to the client.
    pub async fn feed_packet(&mut self, packet: QueuedPacket) -> Result<(), NetworkTransportError> {
        let mut network_transport = self.network_transport.lock().await;
        network_transport.feed_client_packet(packet).await
    }

    /// Feeds client packets into the [`network_transport`]
    ///
    /// Used to queue up packets to be sent to the client.
    pub async fn feed_packets(
        &mut self,
        packet_queue: Vec<QueuedPacket>,
    ) -> Result<(), NetworkTransportError> {
        let mut network_transport = self.network_transport.lock().await;
        network_transport.feed_client_packets(packet_queue).await
    }

    /// Flushes the [`network_transport`].
    ///
    /// Any packets queued up using [`feed_client_packets`] or [`feed_client_packet`] will be sent to the client will be sent immediately.
    pub async fn flush_packets(&mut self) -> Result<(), NetworkTransportError> {
        let mut network_transport = self.network_transport.lock().await;
        network_transport.flush_client_packets().await
    }
}
