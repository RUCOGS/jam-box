extends MarginContainer


@export var _network: Network
@export var _config_relay_button: Button
@export var _connect_relay_button: Button
@export var _relay_address_line_edit: LineEdit
@export var _config_panel: Control
@export var _config_label: Label


func _ready() -> void:
	_config_relay_button.pressed.connect(_on_config_relay_pressed)
	_config_panel.visible = false
	_connect_relay_button.pressed.connect(_on_connect_relay)
	_relay_address_line_edit.text = _network.server_address
	_on_connect_relay()


func _process(delta: float) -> void:
	_update_config_label()


func _on_config_relay_pressed():
	_config_panel.visible = not _config_panel.visible


func _on_connect_relay():
	_network.connect_socket(_relay_address_line_edit.text)
	_update_config_label()


func _update_config_label():
	_connect_relay_button.disabled = _network.state == Network.State.CONNECTING
	_config_label.text = "Relay\n@ %s" % _network.server_address
	if _network.state == Network.State.CONNECTING:
		_config_label.text += "\n(%s, %.1f)" % [Network.State.find_key(_network.state), _network.connect_timer]
	else:
		_config_label.text += "\n(%s)" % Network.State.find_key(_network.state)
