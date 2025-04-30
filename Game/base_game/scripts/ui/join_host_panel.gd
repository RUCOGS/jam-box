extends PanelContainer


@export var _network: Network
@export var _room_manager: RoomManager
@export var _menu_manager: MenuManager
@export var _code_line_edit: LineEdit
@export var _name_line_edit: LineEdit
@export var _join_button: Button
@export var _host_button: Button
@export var _game_option_button: OptionButton
@export var _config: Config
@export var _ui_scaler: UIScaler
@export var _can_host_question: Control
@export var _host_buttons: Control


func _ready() -> void:
	_join_button.pressed.connect(_on_join_pressed)
	_host_button.pressed.connect(_on_host_pressed)
	_room_manager.state_changed.connect(_on_room_state_changed)
	_network.state_changed.connect(_on_room_state_changed)
	_ui_scaler.resolution_platform_changed.connect(_on_resolution_platform_changed)
	_game_option_button.clear()
	for game_info in _config.game_infos:
		_game_option_button.add_item(game_info.name)
		_game_option_button.set_item_metadata(_game_option_button.item_count - 1, game_info.id)
	if _game_option_button.item_count > 0:
		_game_option_button.select(0)
	_on_room_state_changed()


func _on_resolution_platform_changed(is_mobile: bool):
	LimboConsole.print_line("Platform changed: ", is_mobile)
	_can_host_question.visible = is_mobile
	_host_buttons.visible = not is_mobile


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
	var selected_game_id = _game_option_button.get_selected_metadata() as int
	_room_manager.host_room(selected_game_id)
