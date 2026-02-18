class_name CoggleHostManager
extends Control

@export var _coggle_room_manager: CoggleRoomManager
var _room_manager: RoomManager

#player dict here

var _player_data: Dictionary

func _ready() -> void:
	#all sorts of connections
	_room_manager = _coggle_room_manager._room_manager
	
	#listen for packets
	_coggle_room_manager.received_packet.connect(_on_received_packet)
	
	#connect to game start and game end signals
	_room_manager.game_started.connect(_on_game_start)
	_room_manager.game_ended.connect(_on_game_end)
	
	#hide initially
	#visible = false

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
