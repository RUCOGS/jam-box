extends Node
class_name RoomManager


signal state_changed
signal player_connected(client_id: int, username: String)
signal player_disconnected(client_id: int)
signal player_host_changed
signal can_start_changed
signal received_packet(sender_id: int, packet_id: PacketID, buffer: ByteBuffer)
signal game_started
signal game_ended


static var global: RoomManager

#region GENERAL VARS

enum State {
	IDLE,			# Not in a room 
	CONNECTING, 	# Connecting to/making the room
	IN_ROOM,		# Inside a room
	IN_GAME			# Inside a room whose game already started
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
var can_start: bool = false :
	set(v):
		var old = can_start
		can_start = v
		if old != v:
			can_start_changed.emit()
			if is_host:
				# Notify clients changes to can_start
				host_send_can_start(can_start)
var game_info: Config.GameInfo :
	set(v):
		# Don't regenerate game_room_manager if nothing changes
		if game_info == v or not is_inside_tree():
			return
		if game_info:
			game_room_manager.queue_free()
			game_room_manager = null
		game_info = v
		if game_info:
			game_room_manager = game_info.packed_scene.instantiate() as GameRoomManager
			game_room_manager.construct(self)
			add_child(game_room_manager)
var game_room_manager: GameRoomManager

#endregion

#region HOST VARS

# [player_id: int] -> username: String
var players: Dictionary = {}
# Player who can start the game
# 0 means no player has been assigned as a host yet
var player_host: int = 0

#endregion

#region CLIENT VARS

# Can this client start the game?
var is_player_host: bool = false :
	set(v):
		var old = is_player_host
		is_player_host = v
		if old != v:
			player_host_changed.emit()

#endregion

@export var _config: Config
@export var _network: Network
@export var min_players: int = 2
@export var max_players: int = 4

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
	is_player_host = false
	can_start = false
	_network.send_join_room(_room_code, _username)


func host_room(_game_info_id: int):
	room_code = ""
	state = State.CONNECTING
	is_host = true
	is_player_host = false
	can_start = false
	game_info = _config.get_game_info(_game_info_id)
	if game_info == null:
		printerr("GameInfo is NULL!")
	min_players = game_info.min_players
	max_players = game_info.max_players
	_network.send_host_room(max_players)


func _on_disconnected():
	room_code = ""
	username = ""
	state = State.IDLE
	is_host = false
	is_player_host = false
	can_start = false
	game_info = null
	min_players = 0
	max_players = 0
	players.clear()
	player_host = 0
	game_ended.emit()


func _on_received_packet(packet_id: Network.PacketID, buffer: ByteBuffer):
	if state == State.CONNECTING:
		if packet_id == Network.PacketID.JOIN_ROOM_RESULT:
			state = State.IN_ROOM
		elif packet_id == Network.PacketID.HOST_ROOM_RESULT:
			room_code = buffer.get_utf8_string()
			state = State.IN_ROOM
		elif packet_id == Network.PacketID.CLIENT_REQUEST_ERROR:
			state = State.IDLE
	elif state == State.IN_ROOM or state == State.IN_GAME:
		if packet_id == Network.PacketID.CLIENT_RELAY_DATA:
			var sender_id = buffer.get_u16()
			var room_packet_id = buffer.get_u8() as PacketID
			received_packet.emit(sender_id, room_packet_id, buffer)
			_on_received_room_packet(sender_id, room_packet_id, buffer)
		elif is_host:
			if packet_id == Network.PacketID.ROOM_PLAYER_CONNECTED:
				var id = buffer.get_u16()
				var _username = buffer.get_utf8_string()
				print("Player [%s] \"%s\" connected" % [id, _username])
				players[id] = _username
				_host_update_player_host()
				_host_update_player_host()
				
				player_connected.emit(id, _username)
				print("  Lobby: ", players)
			elif packet_id == Network.PacketID.ROOM_PLAYER_DISCONNECTED:
				var client_id = buffer.get_u16()
				print("Player [%s] disconnected" % client_id)
				players.erase(client_id)
				_host_update_player_host()
				player_disconnected.emit(client_id)
				print("  Lobby: ", players)
		


func _on_received_room_packet(sender_id: int, room_packet_id: PacketID, buffer: ByteBuffer):
	if room_packet_id == PacketID.SET_GAME_INFO:
		var game_info_id = buffer.get_u32()
		game_info = _config.get_game_info(game_info_id)
		is_player_host = buffer.get_bool()
	elif room_packet_id == PacketID.SET_CAN_START:
		can_start = buffer.get_bool()
	elif room_packet_id == PacketID.START_GAME:
		state = State.IN_GAME
		game_started.emit()
		if is_host and sender_id == player_host:
			# Only start game if we're on the host and we received the
			# START_GAME packet from the current player_host of the room.
			host_send_start_game()


func _host_update_player_host():
	if not player_host in players:
		if len(players) == 0:
			player_host = 0
		else:
			# Assign player host to next available player
			player_host = players.keys()[0]
			player_host_changed.emit()
			# Notify clients player if they are the new player host
	for player_id in players:
		host_send_set_game_info(player_id)
	can_start = len(players) >= min_players
	if state == State.IN_GAME and is_host and not can_start:
		_network.disconnect_socket()


# Packets for communicating within a room
# These are passed through SERVER_RELAY_DATA and CLIENT_RELAY_DATA packets
enum PacketID {
	# SERVER DEST PACKETS
	TEST_INPUT = 1,				# Players tell the sever if they are pressing down the test button in the lobby screen
	START_GAME = 2,
	
	# CLIENT DEST PACKETS
	SET_GAME_INFO = 128,		# Server tells player whether they are the host or not, and additional game info
	SET_CAN_START = 129,		# Server tells player if they can start the game or not
	
	# MISC
	RELAY_DATA = 200			# Send data to the opposite side
								# host -> sends to all clients, or a specific client
								# client -> sends to host
}


func player_send_test_input(pressed: bool):
	_peer_buffer.clear()
	_peer_buffer.put_u8(PacketID.TEST_INPUT)
	_peer_buffer.put_bool(pressed)
	_network.send_server_relay_data(_peer_buffer.data_array)


# Host client then relays the start game to all players 
func host_send_start_game():
	# This happens to be identical to the implementation of player_send_start_game
	player_send_start_game()


# Player client requests to start game
# Only works for host player
func player_send_start_game():
	_peer_buffer.clear()
	_peer_buffer.put_u8(PacketID.START_GAME)
	_network.send_server_relay_data(_peer_buffer.data_array)


func host_send_set_game_info(player_id: int):
	var is_host = player_id == player_host
	_peer_buffer.clear()
	_peer_buffer.put_u8(PacketID.SET_GAME_INFO)
	_peer_buffer.put_u32(game_info.id)
	_peer_buffer.put_bool(is_host)
	_network.send_server_relay_data(_peer_buffer.data_array, player_id)


func host_send_can_start(_can_start: bool):
	_peer_buffer.clear()
	_peer_buffer.put_u8(PacketID.SET_CAN_START)
	_peer_buffer.put_bool(_can_start)
	_network.send_server_relay_data(_peer_buffer.data_array)


# Relay data to the opposite side
# Player sends a packet to the host
# Host sends a packet to all players (if dest_id = 0), or a specific player of id = dest_id
func send_relay_data(bytes: PackedByteArray, dest_id: int = 0):
	_peer_buffer.clear()
	_peer_buffer.put_u8(PacketID.RELAY_DATA)
	_peer_buffer.put_data(bytes)
	_network.send_server_relay_data(_peer_buffer.data_array, dest_id)
