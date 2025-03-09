extends PanelContainer


@export var _network: Network
@export var _room_manager: RoomManager
@export var _code_label: Label
@export var _username_label: Label
@export var _test_button: Button
@export var _quit_button: Button
@export var _start_button: Button


func _ready() -> void:
	_room_manager.state_changed.connect(_on_state_changed)
	_room_manager.player_host_changed.connect(_on_player_host_changed)
	_room_manager.can_start_changed.connect(_on_can_start_changed)
	_test_button.button_down.connect(_on_test_press_changed.bind(true))
	_test_button.button_up.connect(_on_test_press_changed.bind(false))
	_quit_button.pressed.connect(_on_quit_pressed)
	_start_button.pressed.connect(_on_start_pressed)
	_on_player_host_changed()
	_on_can_start_changed()


func _on_start_pressed():
	_room_manager.player_send_start_game()


func _on_can_start_changed():
	_start_button.disabled = not _room_manager.can_start


func _on_player_host_changed():
	_start_button.visible = _room_manager.is_player_host
	_on_state_changed()


func _on_test_press_changed(pressed: bool):
	_room_manager.player_send_test_input(pressed)


func _on_state_changed():
	if _room_manager.state == RoomManager.State.IN_ROOM:
		_code_label.text = "[%s]" % _room_manager.room_code
		_username_label.text = _room_manager.username
		if _room_manager.is_player_host:
			_code_label.text += " (HOST)"


func _on_quit_pressed():
	_network.restart_socket()
