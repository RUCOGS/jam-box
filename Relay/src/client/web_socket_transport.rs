// Module containing a WebSocket implemention of a [`NetworkTransport`].
use std::{borrow::Cow, future::Future, sync::Arc};

use async_trait::async_trait;
use bytebuffer::ByteBuffer;
use futures_util::{
    stream::{SplitSink, SplitStream},
    SinkExt, StreamExt,
};
use log::error;
use num_enum::TryFromPrimitive;
use thiserror::Error;
use tokio::{net::TcpStream, sync::Mutex};
use tokio_tungstenite::{
    tungstenite::{
        protocol::{frame::coding::CloseCode, CloseFrame},
        Message,
    },
    WebSocketStream,
};

use crate::{packet::PacketID, utils::ByteBufferExt};

use super::{
    network_transport::{NetworkTransport, NetworkTransportError, NetworkTransportRunner},
    QueuedPacket,
};

// A [`NetworkTransport`]` that operates over WebSockets.
pub struct WebSocketTransport {
    pub ws_write_stream: SplitSink<WebSocketStream<TcpStream>, Message>,
    pub ws_read_stream: Arc<Mutex<SplitStream<WebSocketStream<TcpStream>>>>,
}

#[derive(Error, Debug)]
pub enum WebSocketTransportError {
    #[error("missing address: {0}")]
    MissingAddress(std::io::Error),
    #[error("websocket error: {0}")]
    WebSocketError(tokio_tungstenite::tungstenite::Error),
}

impl From<std::io::Error> for WebSocketTransportError {
    fn from(value: std::io::Error) -> Self {
        WebSocketTransportError::MissingAddress(value)
    }
}

impl From<tokio_tungstenite::tungstenite::Error> for WebSocketTransportError {
    fn from(value: tokio_tungstenite::tungstenite::Error) -> Self {
        WebSocketTransportError::WebSocketError(value)
    }
}

impl WebSocketTransport {
    /// Attempts to create a [`WebSocketTransport`] from a WebSocket [`TcpStream`].
    ///
    /// Returns the newly created [`WebSocketTransport`], or a error otherwise.
    pub async fn from_stream(stream: TcpStream) -> Result<Self, WebSocketTransportError> {
        let ws_stream = tokio_tungstenite::accept_async(stream).await?;

        let mut buffer = ByteBuffer::new_little_endian();
        buffer.set_endian(bytebuffer::Endian::LittleEndian);

        let (ws_write_stream, ws_read_stream) = ws_stream.split();

        Ok(WebSocketTransport {
            ws_write_stream: ws_write_stream,
            ws_read_stream: Arc::new(Mutex::new(ws_read_stream)),
        })
    }

    /// Attempts to convert a WebSocket binary message (an array of bytes) into a [`QueuedPacket`].
    ///
    /// This is used by [`NetworkTransportRunner`] to process the incoming bytes from the client to server WebSocket stream.   
    async fn process_binary_message(bytes: Vec<u8>) -> Result<QueuedPacket, NetworkTransportError> {
        let mut buffer = ByteBuffer::from_vec(bytes);
        buffer.set_endian(bytebuffer::Endian::LittleEndian);
        let packet_id = PacketID::try_from_primitive(buffer.read_u8()?)?;

        Ok(QueuedPacket { packet_id, buffer })
    }
}

#[async_trait]
impl NetworkTransport for WebSocketTransport {
    async fn disconnect(&mut self) -> Result<(), NetworkTransportError> {
        // WebSockets should send a CloseFrame to inform the other side about the closure of the socket
        self.ws_write_stream
            .send(Message::Close(Some(CloseFrame {
                code: CloseCode::Normal,
                reason: Cow::from("Server disconnected client"),
            })))
            .await?;
        Ok(())
    }

    async fn feed_client_packet(
        &mut self,
        packet: QueuedPacket,
    ) -> Result<(), NetworkTransportError> {
        self.ws_write_stream.feed(Message::binary(packet)).await?;
        Ok(())
    }

    async fn flush_client_packets(&mut self) -> Result<(), NetworkTransportError> {
        self.ws_write_stream.flush().await?;
        Ok(())
    }
}

#[async_trait]
impl NetworkTransportRunner for WebSocketTransport {
    async fn start_transport_process<Fut>(
        process_fn: impl Fn(QueuedPacket) -> Fut + Send,
        transport: Arc<Mutex<Self>>,
    ) -> Result<(), NetworkTransportError>
    where
        Fut: Future + Send,
    {
        // Creates an reference to the read stream from the WebSocketTransport.
        let ws_read_stream_arc = async {
            let transport = transport.lock().await;
            transport.ws_read_stream.clone()
        }
        .await;
        loop {
            // Repeatedly attempts toi read the next message from the WebSocket read stream.
            let mut ws_read_stream = ws_read_stream_arc.lock().await;
            match ws_read_stream.next().await {
                Some(msg) => match msg {
                    Ok(msg) => {
                        match msg {
                            // Handle the closure of a WebSocket gracefully.
                            Message::Close(_) => return Ok(()),
                            // Convert binary messages into QueuedPackets
                            Message::Binary(bytes) => {
                                match WebSocketTransport::process_binary_message(bytes).await {
                                    Err(e) => {
                                        error!("Error processing message: {}", e);
                                    }
                                    Ok(packet) => {
                                        process_fn(packet).await;
                                    }
                                }
                            }
                            _ => {
                                error!("Unhandled message type: {}", msg);
                            }
                        }
                    }
                    Err(e) => {
                        error!("Error reading WebSocket message: {}", e);
                        return Err(e.into());
                    }
                },
                // Handle an empty stream gracefully.
                None => return Ok(()),
            }
        }
    }
}
