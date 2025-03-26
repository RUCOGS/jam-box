class_name QuiplashHostManager
extends Node

@export var _quiplash_room_manager: QuiplashRoomManager
var _room_manager: RoomManager
var _active_state: QuiplashBaseState

# player id --> dict of player_data
# 0: {
#	"username": "bob",
#	"score": 123,
#	"responded": false
#}

var _player_data: Dictionary
enum States {
	QUESTIONS = 1,
	VOTING = 2,
	SCORING = 3
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_room_manager = _quiplash_room_manager._room_manager
	_quiplash_room_manager.received_packet.connect(_on_received_packet)
	_room_manager.game_started.connect(_on_game_start)
	_room_manager.game_ended.connect(_on_game_end)
	
	for key in _room_manager.players:
		_player_data[key] = {
			"username": _room_manager.players[key],
			"score": 0,
			"responded": false
		}


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (_active_state != null):
		_active_state.update(delta)

func _on_received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer):
	if (_active_state != null):
		_active_state.received_packet(sender_id, packet_id, buffer)

func _go_to_state(state: int):
	#search through children
	#get STATE_NUM from child, see if it matches state
	#if it does, activate it.
	for child: Node in get_children():
		if "STATE_NUM" in child && child.STATE_NUM == state:
			print("Yee haw" + child.thingamabob)
			#exit previous state, set state to active state, enter state, break
			if (_active_state != null):
				_active_state.exit()
			_active_state = child
			_active_state.enter()
			break
	
	#tell players that the state is changing
	_quiplash_room_manager._host_change_phase(state)


func _on_game_start():
	_go_to_state(States.QUESTIONS)

func _on_game_end():
	pass
