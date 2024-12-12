//! Module that contains packet related structs and traits.
//!
//! Packets are messages sent between the client and the server.
//!
//! There are two types of packets: Client and server packets. See [`PacketID`] for more information on packet types.
#![allow(non_upper_case_globals)]

use num_enum::{IntoPrimitive, TryFromPrimitive};

use crate::client::Client;

/// Represents a type of packet packets sent between the clients and the server.
///
/// There are two types of packets:
/// - Client packets, which are packets destined for the client. They are sent from the server to the client.
///     - **Ex.** ClientUpdate, which updates the client on changes to the world in a small radius around the player
/// - Server packets, which are packets destined for the server. They are sent from the client to the server.
///     - **Ex.** PlayerMove, which notifies the server that the client's player has moved
#[derive(Debug, Eq, PartialEq, TryFromPrimitive, IntoPrimitive, Clone, Copy, Hash)]
#[repr(u8)]
pub enum PacketID {
    // CLIENT PACKETS
    /// Server response to a HostGame packet
    HostGameResult = 1,
    /// Server is relaying data to Client (Player/Host)
    ClientRelayData = 2,
    /// Server tells client to disconnect
    ClientDisconnect = 3,
    /// Server response to a JoinGame packet
    JoinGameResult = 4,
    /// Server encountering an error processing client request packet
    ClientRequestError = 5,

    // SERVER PACKETS
    /// Client host attempts to register account with the server
    HostGame = 128,
    /// Client player attempts to join a game
    JoinGame = 129,
    /// Client (Player/Host) is sending data
    ServerRelayData = 130,
    /// Client host attempts to end game
    HostEndGame = 131,
}

/// Packets destined for the server. Clients send server packets to the server.
/// These packets are meant to be processed by the server.
pub const SERVER_PACKETS: [PacketID; 3] = [
    // SERVER PACKETS
    PacketID::HostGameResult,
    PacketID::ClientRelayData,
    PacketID::ClientDisconnect,
];

/// Packets destined for the client. The server sends client packets to a client.
/// These packets are meant to be processed by the client.
pub const CLIENT_PACKETS: [PacketID; 4] = [
    PacketID::HostGame,
    PacketID::JoinGame,
    PacketID::ServerRelayData,
    PacketID::HostEndGame,
];

impl PacketID {
    /// Checks if a packet is contained within [`SERVER_PACKETS`]
    pub fn is_server_packet(&self) -> bool {
        SERVER_PACKETS.contains(self)
    }

    /// Checks if a packet is contained within [`CLIENT_PACKETS`]
    pub fn is_client_packet(&self) -> bool {
        CLIENT_PACKETS.contains(self)
    }
}
