extends Control
class_name MenuManager


@export var _room_manager: RoomManager


func _ready() -> void:
	_room_manager.game_started.connect(_on_game_started)
	_room_manager.game_ended.connect(_on_game_ended)


func _on_game_started():
	go_to_menu("InGamePanel")


func _on_game_ended():
	go_to_menu("JoinHostPanel")


func go_to_menu(menu_name: String):
	for child: Control in get_children():
		child.visible = child.name == menu_name
