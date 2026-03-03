class_name CoggleHostManager
extends Node2D

@export var _coggle_room_manager: CoggleRoomManager
@export var _host_world: HostWorld

var _room_manager: RoomManager
var viewport_size: Vector2i
#player dict here

var _player_data: Dictionary

#Host Manager controls time between turns, updates UI, and other high-level game stuff
#Physics processing can be left to the HostWorld node

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
	_host_world.update_bounding_rect(viewport_size)
	
	#hide initially
	visible = false

func _on_received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer):
	#handle packets here
	pass

func _on_game_start():
	#get all players, add them to a dictionary with some information about them
	for key in _room_manager.players:
		_player_data[key] = {
			"username": _room_manager.players[key],
			"team": 0,
			#etc
		}
	visible = true
	
func _on_game_end():
	pass
