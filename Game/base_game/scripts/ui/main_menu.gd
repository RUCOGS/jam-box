extends Control


@export var _network: Network
@export var _menu_manager: MenuManager


func _ready() -> void:
	_network.disconnected.connect(_on_disconnected)
	_on_disconnected()


func _on_disconnected():
	visible = true
	_menu_manager.go_to_menu("JoinHostPanel")
