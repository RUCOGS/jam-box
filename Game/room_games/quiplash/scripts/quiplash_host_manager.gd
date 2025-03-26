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

#array of all questions
var _all_questions: Array

@export var questions_needed: int
# dict of question data:
# "question": "string", 
# "responses": [{"respondent_id": 12, "response": "String"}, ...],
# 
# 
var chosen_questions: Array

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_room_manager = _quiplash_room_manager._room_manager
	_quiplash_room_manager.received_packet.connect(_on_received_packet)
	_room_manager.game_started.connect(_on_game_start)
	_room_manager.game_ended.connect(_on_game_end)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (not (_active_state == null)):
		_active_state.update(delta)

func _on_received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer):
	if (not (_active_state == null)):
		_active_state.received_packet(sender_id, packet_id, buffer)

func _go_to_state(state: int):
	#search through children
	#get STATE_NUM from child, see if it matches state
	#if it does, activate it.
	for child: Node in get_children():
		if "STATE_NUM" in child and child.STATE_NUM == state:
			print("Host changing state... " + child.thingamabob)
			#exit previous state, set state to active state, enter state, break
			if (not (_active_state == null)):
				_active_state.exit()
			_active_state = child
			_active_state.enter()
			break
	
	#tell players that the state is changing
	_quiplash_room_manager._host_change_phase(state)

func _read_questions():
	var questions_file = FileAccess.open("res://room_games/quiplash/assets/questions_list.txt", FileAccess.READ)
	while (questions_file.get_position() < questions_file.get_length()):
		_all_questions.push_back(questions_file.get_line())
	questions_file.close()
	
func _choose_questions():
	_all_questions.shuffle()
	for i in questions_needed:
		var _current_question = "uh oh"
		if (i < _all_questions.size()):
			_current_question = _all_questions[i]
		var question_dict = {
			"question": _current_question,
			"responses": []
		}
		chosen_questions.push_back(question_dict)
	
func _on_game_start():
	for key in _room_manager.players:
		_player_data[key] = {
			"username": _room_manager.players[key],
			"score": 0,
			"responded": false
		}
	
	questions_needed = 2 * _player_data.size()
	
	_read_questions()
	_choose_questions()
	_go_to_state(States.QUESTIONS)

func _on_game_end():
	pass
