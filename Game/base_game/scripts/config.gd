class_name Config
extends Node


class GameInfo:
	var id: int
	var name: String
	var description: String
	var packed_scene: PackedScene
	var min_players: int
	var max_players: int

static var global: Config

@export var games: Array[PackedScene]
var game_infos: Array[GameInfo]


func get_game_info(id: int):
	for g in game_infos:
		if g.id == id:
			return g
	return null


func _enter_tree() -> void:
	if global != null:
		queue_free()
		return
	global = self
	for game_scene in games:
		var root = game_scene.instantiate()
		var room_manager = root as GameRoomManager
		var game_info = GameInfo.new()
		game_info.id = room_manager.id
		game_info.name = room_manager.game_name
		game_info.description = room_manager.game_description
		game_info.min_players = room_manager.min_players
		game_info.max_players = room_manager.max_players
		game_info.packed_scene = game_scene
		game_infos.append(game_info)
		root.queue_free()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if global == self:
			global = null
