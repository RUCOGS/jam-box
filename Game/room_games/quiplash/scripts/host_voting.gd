extends QuiplashBaseState

@export var _quiplash_host_manager: QuiplashHostManager
@export var _quiplash_room_manager: QuiplashRoomManager

var _current_question: Dictionary

var _players_responded
var _total_players

func _ready() -> void:
	STATE_NUM = States.VOTING
	STATE_DURATION = Duration.VOTING
	_total_players = _quiplash_host_manager._player_data.size()

func received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer):
	pass

#when the state is first entered.
func enter():
	_current_question = _quiplash_host_manager.chosen_questions.pop_front()
	

#when the state is exited (called before the next state is entered)
func exit():
	pass

#called every frame in the manager
func update(_delta: float):
	pass
