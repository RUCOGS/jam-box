extends MarginContainer


@export var _network: Network
@export var _quit_button: Button


func _ready():
	_quit_button.pressed.connect(_on_quit_pressed)


func _on_quit_pressed():
	_network.disconnect_socket()
