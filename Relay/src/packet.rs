//! Module that contains packet related structs and traits.
//!
//! Packets are messages sent between the client and the server.
//!
//! There are two types of packets: Client and server packets. See [`PacketID`] for more information on packet types.
#![allow(non_upper_case_globals)]

use num_enum::{IntoPrimitive, TryFromPrimitive};

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
    /// Server response to a HostRoom packet
    HostRoomResult = 1,
    /// Server response to a JoinRoom packet.
    JoinRoomResult = 2,
    /// Server is relaying data to Client (Player/Host)
    ClientRelayData = 3,
    /// Server tells client to disconnect
    ClientDisconnect = 4,
    /// Server tells host a player has disconnected
    RoomPlayerDisconnected = 5,
    /// Server tells host a player has connected.
    RoomPlayerConnected = 6,
    /// Server encountering an error processing client request packet.
    ClientRequestError = 7,

    // SERVER PACKETS
    /// Client host attempts to register account with the server.
    HostRoom = 128,
    /// Client player attempts to join a game room.
    JoinRoom = 129,
    /// Client (Player/Host) is sending data.
    ServerRelayData = 130,
    /// Client host attempts to end its game room. Only works when the client is hosting a room.
    HostEndRoom = 131,
}

/// Packets destined for the server. Clients send server packets to the server.
/// These packets are meant to be processed by the server.
pub const SERVER_PACKETS: [PacketID; 7] = [
    // SERVER PACKETS
    PacketID::HostRoomResult,
    PacketID::ClientRelayData,
    PacketID::ClientDisconnect,
    PacketID::RoomPlayerDisconnected,
    PacketID::RoomPlayerConnected,
    PacketID::JoinRoomResult,
    PacketID::ClientRequestError,
];

/// Packets destined for the client. The server sends client packets to a client.
/// These packets are meant to be processed by the client.
pub const CLIENT_PACKETS: [PacketID; 4] = [
    PacketID::HostRoom,
    PacketID::JoinRoom,
    PacketID::ServerRelayData,
    PacketID::HostEndRoom,
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
