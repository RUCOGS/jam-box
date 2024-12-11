extends Node
class_name Network


signal connected
signal disconnected(error: String)


static var global: Network

# The URL we will connect to.
@export var websocket_url = "ws://127.0.0.1:9955"

enum State {
	IDLE,
	CONNECTING,
	CONNECTED,
}

var state: State = State.IDLE
# [PacketID]: packet_handler
var packet_handlers_dict: Dictionary = {}

var _socket = WebSocketPeer.new()
var _peer_buffer = ByteBuffer.new_little_endian()


func _ready():
	if global != null:
		queue_free()
		return
	global = self
	set_process(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if global == self:
			global = null


func add_packet_handler(packet_id: PacketID, callable: Callable):
	packet_handlers_dict[packet_id] = callable


func remove_packet_handler(packet_id: PacketID):
	packet_handlers_dict.erase(packet_id)


func connect_socket(_server_address: String = self.server_address):
	self.server_address = _server_address
	_socket.connect_to_url(_server_address)
	state = State.CONNECTING
	set_process(true)


func disconnect_socket():
	_socket.close()


func _process(_delta):
	# Call this in _process or _physics_process. Data transfer and state updates
	# will only happen when calling this function.
	_socket.poll()

	# get_ready_state() tells you what state the _socket is in.
	var state = _socket.get_ready_state()

	# WebSocketPeer.STATE_OPEN means the _socket is connected and ready
	# to send and receive data.
	if state == WebSocketPeer.STATE_OPEN:
		while _socket.get_available_packet_count():
			var packet = _socket.get_packet()
			var buffer = ByteBuffer.new_little_endian()
			buffer.data_array = packet
			var packet_id = buffer.get_u8() as PacketID
			var callable = packet_handlers_dict.get(packet_id)
			if callable != null:
				(callable as Callable).call(buffer)
	# WebSocketPeer.STATE_CLOSING means the _socket is closing.
	# It is important to keep polling for a clean close.
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	# WebSocketPeer.STATE_CLOSED means the connection has fully closed.
	# It is now safe to stop polling.
	elif state == WebSocketPeer.STATE_CLOSED:
		# The code will be -1 if the disconnection was not properly notified by the remote peer.
		var code = _socket.get_close_code()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false) # Stop procesing


enum PacketID {
	# CLIENT PACKETS
	HOST_GAME_RESULT = 1,
	CLIENT_RELAY_DATA = 2,
	CLIENT_DISCONNECT = 3,

	# SERVER PACKETS
	HOST_GAME = 128,
	JOIN_GAME = 129,
	SERVER_RELAY_DATA = 130,
	HOST_END_GAME = 131,
}


func send_packet(bytes: PackedByteArray):
	_socket.send(bytes)


func send_host_game_packet():
	_peer_buffer.clear()
	_peer_buffer.put_u8(PacketID.HOST_GAME)
	send_packet(_peer_buffer.data_array)


func send_join_game_packet(code: String):
	_peer_buffer.clear()
	_peer_buffer.put_u8(PacketID.JOIN_GAME)
	_peer_buffer.put_utf8_string(code)
	send_packet(_peer_buffer.data_array)
