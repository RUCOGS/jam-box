extends PanelContainer


@export var _network: Network
@export var _room_manager: RoomManager
@export var _code_label: Label
@export var _test_button: Button
@export var _quit_button: Button


func _ready() -> void:
	_room_manager.state_changed.connect(_on_state_changed)
	_test_button.button_down.connect(_on_test_press_changed.bind(true))
	_test_button.button_up.connect(_on_test_press_changed.bind(false))
	_quit_button.pressed.connect(_on_quit_pressed)


func _on_test_press_changed(pressed: bool):
	_room_manager.send_test_input(pressed)


func _on_state_changed():
	if _room_manager.state == RoomManager.State.IN_ROOM:
		_code_label.text = "[%s]" % _room_manager.room_code


func _on_quit_pressed():
	_network.restart_socket()
