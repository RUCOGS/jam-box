extends Node
class_name RoomManager


signal state_changed
signal player_connected(client_id: int, username: String)
signal player_disconnected(client_id: int)
signal received_packet(sender_id: int, packet_id: PacketID, buffer: ByteBuffer)


static var global: RoomManager

enum State {
	IDLE,		# Not in a room 
	CONNECTING, 	# Connecting to/making the room
	IN_ROOM		# Inside a room
}

var state: State = State.IDLE :
	set(v):
		var old = state
		state = v
		if old != v:
			state_changed.emit()
var room_code: String = ""
# Current player's username. Set if you are not the host.
var username: String = ""
var is_host: bool = false
# [player_id: int] -> username: String
# Set if are you the host.
var players: Dictionary = {}

@export var _network: Network

var _peer_buffer = ByteBuffer.new_little_endian()


func _enter_tree() -> void:
	if global != null:
		queue_free()
		return
	global = self


func _ready() -> void:
	_network.received_packet.connect(_on_received_packet)
	_network.disconnected.connect(_on_disconnected)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and global == self:
		global = null


func join_room(_room_code: String, _username: String):
	room_code = _room_code
	username = _username
	state = State.CONNECTING
	is_host = false
	_network.send_join_room(_room_code, _username)


func host_room():
	room_code = ""
	state = State.CONNECTING
	is_host = true
	players.clear()
	_network.send_host_room()


func _on_disconnected():
	state = State.IDLE
	is_host = false
	room_code = ""


func _on_received_packet(packet_id: Network.PacketID, buffer: ByteBuffer):
	if state == State.CONNECTING:
		if packet_id == Network.PacketID.JOIN_ROOM_RESULT:
			state = State.IN_ROOM
		elif packet_id == Network.PacketID.HOST_ROOM_RESULT:
			room_code = buffer.get_utf8_string()
			state = State.IN_ROOM
		elif packet_id == Network.PacketID.CLIENT_REQUEST_ERROR:
			state = State.IDLE
	elif state == State.IN_ROOM:
		if packet_id == Network.PacketID.CLIENT_RELAY_DATA:
			var sender_id = buffer.get_u32()
			var room_packet_id = buffer.get_u8() as PacketID
			received_packet.emit(sender_id, room_packet_id, buffer)
		elif is_host:
			if packet_id == Network.PacketID.ROOM_PLAYER_CONNECTED:
				var id = buffer.get_u32()
				var username = buffer.get_utf8_string()
				print("Player [%s] \"%s\" connected" % [id, username])
				players[id] = username
				player_connected.emit(id, username)
				print("  Lobby: ", players)
			elif packet_id == Network.PacketID.ROOM_PLAYER_DISCONNECTED:
				var client_id = buffer.get_u32()
				print("Player [%s] disconnected" % client_id)
				players.erase(client_id)
				player_disconnected.emit(client_id)
				print("  Lobby: ", players)
			


# Packets for communicating within a room
# These are passed through SERVER_RELAY_DATA and CLIENT_RELAY_DATA packets
enum PacketID {
	TEST_INPUT = 1	# Used to indicate if a player is pressing down the test button in the lobby screen
}


func send_test_input(pressed: bool):
	_peer_buffer.clear()
	_peer_buffer.put_u8(PacketID.TEST_INPUT)
	_peer_buffer.put_bool(pressed)
	_network.send_relay_data(_peer_buffer.data_array)
