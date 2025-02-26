class_name GameRoomManager
extends Node


signal received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer)


@export var id: int
@export var game_name: String
@export var game_description: String
@export var min_players: int
@export var max_players: int

var _room_manager: RoomManager
var _packet_buffer = ByteBuffer.new_little_endian()


func construct(_room_manager: RoomManager):
	self._room_manager = _room_manager
	self._room_manager.received_packet.connect(_on_received_room_packet)


func _on_received_room_packet(sender_id: int, packet_id: int, buffer: ByteBuffer):
	_on_received_game_packet(sender_id, buffer)


func _on_received_game_packet(sender_id: int, buffer: ByteBuffer):
	pass


func send_to_all_players(bytes: PackedByteArray):
	self._room_manager.send_relay_data(bytes)


func send_to_host(bytes: PackedByteArray):
	self._room_manager.send_relay_data(bytes)


func send_to_player(bytes: PackedByteArray, dest_id: int):
	self._room_manager.send_relay_data(bytes, dest_id)
