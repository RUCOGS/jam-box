extends Node
class_name NetworkServer


@export var port: int = 9080

var tcp_server: TCPServer = TCPServer.new()
var socket: WebSocketPeer = WebSocketPeer.new()


func _ready() -> void:
	if tcp_server.listen(port) != OK:
		push_error("Network Server: Unable to start server.")
		set_process(false)


func _process(_delta: float) -> void:
	# Take in incoming connections
	while tcp_server.is_connection_available():
		var conn: StreamPeerTCP = tcp_server.take_connection()
		assert(conn != null)
		socket.accept_stream(conn)

	socket.poll()

	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			log_message(socket.get_packet().get_string_from_ascii())
