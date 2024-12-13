extends Node
class_name Network


signal connected
signal state_changed
signal disconnected
signal received_packet(packet_id: PacketID, buffer: ByteBuffer)


static var global: Network

@export var server_address: String = "ws://127.0.0.1:9955"
@export var connect_timeout: float = 5

enum State {
	IDLE,
	CONNECTING,
	CONNECTED,
}

var state: State = State.IDLE :
	set(v):
		var old = state
		state = v
		if old != v:
			state_changed.emit()
# [PacketID]: packet_handler
var packet_handlers_dict: Dictionary = {}
var connect_timer: float = 0

var _socket = WebSocketPeer.new()
var _peer_buffer = ByteBuffer.new_little_endian()


func _enter_tree() -> void:
	if global != null:
		queue_free()
		return
	global = self
	set_process(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if global == self:
			global = null


func connect_socket(_server_address: String = self.server_address):
	if state != State.IDLE:
		await disconnect_socket()
	self.server_address = _server_address
	_socket.connect_to_url(_server_address)
	state = State.CONNECTING
	connect_timer = connect_timeout
	set_process(true)


func restart_socket():
	await connect_socket()


func disconnect_socket():
	_socket.close()
	await disconnected


func _process(delta):
	# Poll for new incoming packets from the web socket
	_socket.poll()

	# get_ready_state() tells you what state the _socket is in.
	var socket_state = _socket.get_ready_state()

	# WebSocketPeer.STATE_OPEN means the _socket is connected and ready
	# to send and receive data.
	if socket_state == WebSocketPeer.STATE_CONNECTING:
		connect_timer -= delta
		if connect_timer < 0:
			disconnect_socket()
	elif socket_state == WebSocketPeer.STATE_OPEN:
		if state != State.CONNECTED:
			state = State.CONNECTED
			connected.emit()
		while _socket.get_available_packet_count():
			var packet = _socket.get_packet()
			var buffer = ByteBuffer.new_little_endian()
			buffer.data_array = packet
			var packet_id = buffer.get_u8() as PacketID
			received_packet.emit(packet_id, buffer)
	# WebSocketPeer.STATE_CLOSING means the _socket is closing.
	# It is important to keep polling for a clean close.
	elif socket_state == WebSocketPeer.STATE_CLOSING:
		pass
	# WebSocketPeer.STATE_CLOSED means the connection has fully closed.
	# It is now safe to stop polling.
	elif socket_state == WebSocketPeer.STATE_CLOSED:
		state = State.IDLE
		# The code will be -1 if the disconnection was not properly notified by the remote peer.
		var code = _socket.get_close_code()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false)
		disconnected.emit()


enum PacketID {
	# CLIENT PACKETS
	# Server response to a HostRoom packet
	HOST_ROOM_RESULT = 1,
	# Server response to a JoinRoom packet.
	JOIN_ROOM_RESULT = 2,
	# Server is relaying data to Client (Player/Host)
	CLIENT_RELAY_DATA = 3,
	# Server tells client to disconnect
	CLIENT_DISCONNECT = 4,
	# Server tells host a player has disconnected
	ROOM_PLAYER_DISCONNECTED = 5,
	# Server tells host a player has connected.
	ROOM_PLAYER_CONNECTED = 6,
	# Server encountering an error processing client request packet.
	CLIENT_REQUEST_ERROR = 7,

	# SERVER PACKETS
	# Client host attempts to register account with the server.
	HOST_ROOM = 128,
	# Client player attempts to join a game room.
	JOIN_ROOM = 129,
	# Client (Player/Host) is sending data.
	SERVER_RELAY_DATA = 130
}


func send_packet(bytes: PackedByteArray):
	_socket.send(bytes)


func send_host_room():
	_peer_buffer.clear()
	_peer_buffer.put_u8(PacketID.HOST_ROOM)
	send_packet(_peer_buffer.data_array)


func send_join_room(code: String, username: String):
	_peer_buffer.clear()
	_peer_buffer.put_u8(PacketID.JOIN_ROOM)
	_peer_buffer.put_utf8_string(code)
	_peer_buffer.put_utf8_string(username)
	send_packet(_peer_buffer.data_array)


func send_relay_data(bytes: PackedByteArray):
	_peer_buffer.clear()
	_peer_buffer.put_u8(PacketID.SERVER_RELAY_DATA)
	_peer_buffer.put_data(bytes)
	send_packet(_peer_buffer.data_array)
