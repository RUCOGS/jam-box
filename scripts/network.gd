extends Node
class_name Network

# The URL we will connect to.
@export var websocket_url = "wss://localhost"

# Our WebSocketClient instance.
var socket = WebSocketPeer.new()

func _ready():
	# Initiate connection to the given URL.
	var err = socket.connect_to_url(websocket_url)
	if err != OK:
		print("Unable to connect")
		set_process(false)
	else:
		# Wait for the socket to connect.
		await get_tree().create_timer(2).timeout

		# Send data.
		socket.send_text("Test packet")
