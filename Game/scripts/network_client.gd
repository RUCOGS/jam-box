extends Node
class_name NetworkClient

# The URL we will connect to.
@export var websocket_url = "wss://atlinx.net:9955"

var _socket = WebSocketPeer.new()
var _peer_buffer = ByteBuffer.new_little_endian()

func _ready():
	# Initiate connection to the given URL.
	var err = _socket.connect_to_url(websocket_url)
	if err != OK:
		print("Unable to connect")
		set_process(false)
	else:
		# Wait for the _socket to connect.
		await get_tree().create_timer(2).timeout

		# Send data.
		send_host_game_packet()


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
			print("Got data from server: ", _socket.get_packet().get_string_from_utf8())

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
		set_process(false) # Stop p


func send_packet(bytes: PackedByteArray):
	_socket.send(bytes)


#region PacketIDs

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

#endregion


func send_host_game_packet():
	_peer_buffer.clear()
	_peer_buffer.put_u8(PacketID.HOST_GAME)
	send_packet(_peer_buffer.data_array)
