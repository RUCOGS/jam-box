class_name GameRoomManager
extends Node


@export var id: int
@export var game_name: String
@export var game_description: String
@export var min_players: int
@export var max_players: int
@export var allow_audience: bool = false

var _room_manager: RoomManager
var _packet_buffer = ByteBuffer.new_little_endian()


func construct(_room_manager: RoomManager):
	self._room_manager = _room_manager
	self._room_manager.game_started.connect(_game_started)
	self._room_manager.game_ended.connect(_game_ended)
	self._room_manager.received_packet.connect(_on_received_room_packet)


func _on_received_room_packet(sender_id: int, packet_id: int, buffer: ByteBuffer):
	if packet_id == RoomManager.PacketID.RELAY_DATA:
		var _buffer = ByteBuffer.new_little_endian()
		_buffer.put_data(buffer.data_array)
		_buffer.seek(buffer.get_position())
		_on_received_game_packet(sender_id, _buffer)


# Virtual function
# Called when the game is started
func _game_started():
	pass


# Virtual function
# Called when the game is ended
func _game_ended():
	pass


# Virtual function
# Called when the game received a packet it sent
func _on_received_game_packet(sender_id: int, buffer: ByteBuffer):
	pass


func send_to_all_players(bytes: PackedByteArray):
	self._room_manager.send_relay_data(bytes)


func send_to_host(bytes: PackedByteArray):
	self._room_manager.send_relay_data(bytes)


func send_to_player(bytes: PackedByteArray, dest_id: int):
	self._room_manager.send_relay_data(bytes, dest_id)
