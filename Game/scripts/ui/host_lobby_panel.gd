extends PanelContainer


@export var _network: Network
@export var _room_manager: RoomManager
@export var _code_label: Label
@export var _players_label: Label
@export var _start_button: Button
@export var _quit_button: Button

# [player_id: int] -> bool (pressed)
var _player_to_test_pressed: Dictionary = {}


func _ready() -> void:
	_room_manager.state_changed.connect(_on_state_changed)
	_room_manager.received_packet.connect(_on_received_packet)
	_room_manager.player_connected.connect(_on_player_connected)
	_room_manager.player_disconnected.connect(_on_player_disconnected)


func _on_state_changed():
	if _room_manager.state == RoomManager.State.IN_ROOM:
		_code_label.text = "[%s]" % _room_manager.room_code
		_player_to_test_pressed.clear()


func _on_received_packet(sender_id: int, packet_id: RoomManager.PacketID, buffer: ByteBuffer):
	if packet_id == RoomManager.PacketID.TEST_INPUT:
		var test_pressed = buffer.get_bool()
		_player_to_test_pressed[sender_id] = test_pressed
		_update_visuals()


func _on_player_connected(player_id: int):
	_player_to_test_pressed[player_id] = false
	_update_visuals()


func _on_player_disconnected(player_id: int):
	_player_to_test_pressed.erase(player_id)
	_update_visuals()


func _update_visuals():
	var text = ""
	for player in _room_manager.players:
		text += "[%s] %s\n" % [player, "(TEST)" if _player_to_test_pressed[player] else ""]
	text = text.rstrip("\n")
	_players_label.text = text


func _on_quit_pressed():
	_network.restart_socket()
