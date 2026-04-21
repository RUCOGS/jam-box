class_name CogglePlayerManager
extends Node2D

@export var _coggle_room_manager: CoggleRoomManager
@export var _player_world: PlayerWorld

var _room_manager: RoomManager
var viewport_size: Vector2i

func _ready() -> void:
	#all sorts of connections
	_room_manager = _coggle_room_manager._room_manager
	
	#listen for packets
	_coggle_room_manager.received_packet.connect(_on_received_packet)
	
	#connect to game start and game end signals
	_room_manager.game_started.connect(_on_game_start)
	_room_manager.game_ended.connect(_on_game_end)
	
	#get and update screen size
	viewport_size = get_window().size
	_player_world.update_bounding_rect(viewport_size)
	
	#hide initially
	visible = false

func _on_received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer):
	_player_world.received_packet(sender_id, packet_id, buffer)

func _on_game_start():
	_player_world.game_start()
	visible = true

func _on_game_end():
	pass
