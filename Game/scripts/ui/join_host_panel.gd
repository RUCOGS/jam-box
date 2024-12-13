extends PanelContainer


@export var _network: Network
@export var _room_manager: RoomManager
@export var _menu_manager: MenuManager
@export var _code_line_edit: LineEdit
@export var _name_line_edit: LineEdit
@export var _join_button: Button
@export var _host_button: Button


func _ready() -> void:
	_join_button.pressed.connect(_on_join_pressed)
	_host_button.pressed.connect(_on_host_pressed)
	_room_manager.state_changed.connect(_on_room_state_changed)
	_network.state_changed.connect(_on_room_state_changed)
	_on_room_state_changed()


func _on_room_state_changed():
	var disable_buttons = _room_manager.state == RoomManager.State.CONNECTING or _network.state != Network.State.CONNECTED
	_join_button.disabled = disable_buttons
	_host_button.disabled = disable_buttons
	if _room_manager.state == RoomManager.State.IN_ROOM:
		if _room_manager.is_host:
			_menu_manager.go_to_menu("HostLobbyPanel")
		else:
			_menu_manager.go_to_menu("PlayerLobbyPanel")


func _on_join_pressed():
	_room_manager.join_room(_code_line_edit.text, _name_line_edit.text)


func _on_host_pressed():
	_room_manager.host_room()
