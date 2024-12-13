//! Module containing `NetworkTransport`` related traits.
//!
//! A [`NetworkTransport``] connects a client to a server, allowing the server to read and write packets from and to the client.
use std::{error::Error, fmt::Display, future::Future, sync::Arc};

use async_trait::async_trait;
use log::info;
use tokio::sync::Mutex;

use super::QueuedPacket;

/// A channel that connects a client to the server.
/// The server can read server packets from the `server_packet_queue()` and can write client packets into using `feed_client_packet()`.
///
/// A `NetworkTransport` should ideally implement [`NetworkTransportRunner``], which creates a message parsing loop for the channel.  
///
/// See [`WebSocketTransport`] for an implementation example.
///
/// # Example
/// ```rust
/// # use mini_mmo::packet::PacketID;
/// # use mini_mmo::client::{QueuedPacket, network_transport::NetworkTransport};
/// # use bytebuffer::ByteBuffer;
/// # let maybe_transport: Option<Box<dyn NetworkTransport>> = None;
/// # if let Some(some_transport) = maybe_transport {
/// let mut transport: Box<dyn NetworkTransport> = some_transport;
///
/// // Reading incoming server packets from the client.
/// let server_packet_queue = transport.get_server_packet_queue();
/// let next_incoming_server_packet = server_packet_queue.pop();
///
/// // Sending packets to the client.
/// //
/// // Note that actual packets will have relevant packet data in the QueuedPacket's buffer.
/// // This example uses dummy packets with empty buffers.
/// transport.feed_and_flush_packet(QueuedPacket {
///     packet_id: PacketID::ClientRelayData,
///     buffer: ByteBuffer::new()
/// });
/// transport.feed_and_flush_packets(vec![
///     QueuedPacket {
///         packet_id: PacketID::ClientRelayData,
///         buffer: ByteBuffer::new(),
///     },
///     QueuedPacket {
///         packet_id: PacketID::ClientRelayData,
///         buffer: ByteBuffer::new()
///     }
/// ]);
///
/// // Queueing up packets to the client, without sending immediately.
/// transport.feed_client_packet(QueuedPacket {
///     packet_id: PacketID::ClientRelayData,
///     buffer: ByteBuffer::new()
/// });
/// transport.feed_client_packets(vec![
///     QueuedPacket {
///         packet_id: PacketID::ClientRelayData,
///         buffer: ByteBuffer::new(),
///     },
///     QueuedPacket {
///         packet_id: PacketID::ClientRelayData,
///         buffer: ByteBuffer::new()
///     }
/// ]);
///
/// // Sending queued up client packets to the client immediately.
/// transport.flush_client_packets();
///
/// // Disconnect the transport
/// transport.disconnect();
/// # }
/// ````
#[async_trait]
pub trait NetworkTransport: Send + Sync {
    /// Feeds a client packet into the outgoing client packet queue and then flushes the queue.
    ///
    /// All packets within the outgoing client packet queue are sent immediately.
    async fn feed_and_flush_packet(
        &mut self,
        packet: QueuedPacket,
    ) -> Result<(), NetworkTransportError> {
        self.feed_client_packet(packet).await?;
        self.flush_client_packets().await
    }

    /// Feeds packets into outgoing client packet queue and then flushes the queue.
    ///
    /// All packets within the outgoing client packet queue are sent immediately.
    async fn feed_and_flush_packets(
        &mut self,
        packet_queue: Vec<QueuedPacket>,
    ) -> Result<(), NetworkTransportError> {
        self.feed_client_packets(packet_queue).await?;
        self.flush_client_packets().await
    }

    /// Feeds multiple packets into outgoing client packet queue.
    ///
    /// The packets may not necessarily be sent immediately.
    /// Use [`feed_and_flush_packets`] to send packets immediately to the client.
    async fn feed_client_packets(
        &mut self,
        packet_queue: Vec<QueuedPacket>,
    ) -> Result<(), NetworkTransportError> {
        for packet in packet_queue {
            self.feed_client_packet(packet).await?;
        }
        Ok(())
    }

    /// Feeds a packet into outgoing client packet queue.
    ///
    /// The packet may not necessarily be sent immediately.
    /// Use [`feed_and_flush_packet`] to send a packet immediately to the client.
    async fn feed_client_packet(
        &mut self,
        packet: QueuedPacket,
    ) -> Result<(), NetworkTransportError>;

    /// Flushes the outoing client packet queue.
    ///
    /// Any packets queued up using [`feed_client_packets`] or [`feed_client_packet`] will be sent to the client will be sent immediately.
    async fn flush_client_packets(&mut self) -> Result<(), NetworkTransportError>;

    /// Closes the connection between the client and the server.
    async fn disconnect(&mut self) -> Result<(), NetworkTransportError>;
}

/// A trait that implements an async runner function that listens and processses server packets received from a client.
///
/// The runner is usually ran on a separate async thread by the server.
/// See [`WebSocketTransport`] and [`WebSocketServer`] for an implementation example.
#[async_trait]
pub trait NetworkTransportRunner {
    async fn start_transport_process<Fut>(
        process_fn: impl Fn(QueuedPacket) -> Fut + Send,
        transport: Arc<Mutex<Self>>,
    ) -> Result<(), NetworkTransportError>
    where
        Fut: Future + Send;
}

/// An error that can occur in the [`NetworkTransport`].  
#[derive(Debug)]
pub struct NetworkTransportError(pub Box<dyn Error + Sync + Send>);

impl<T: Error + Sync + Send + 'static> From<T> for NetworkTransportError {
    fn from(value: T) -> Self {
        NetworkTransportError(Box::new(value))
    }
}

impl Display for NetworkTransportError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "NetworkTransportError: {}", self.0)
    }
}
