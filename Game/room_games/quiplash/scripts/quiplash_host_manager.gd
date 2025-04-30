class_name QuiplashHostManager
extends Control

@export var _host_timer: Control
@export var _quiplash_room_manager: QuiplashRoomManager
var _room_manager: RoomManager
var _active_state: QuiplashBaseState


# player id --> dict of player_data
# 0: {
#	"username": "bob",
#	"score": 123,
#	"answered_questions": 0,
#	"voted": false
#	"question_ids": [2, 3, 1]
# }
var _player_data: Dictionary
enum States {
	QUESTIONS = 1,
	VOTING = 2,
	SCORING = 3
}

# Queue of all questions, shuffled
# We can pop from queue to get a new random question
var all_question_queue: Array
#number of questions needed
@export var questions_needed: int

# Array of active question data:
# [{
# 	"question": "string", 
#   "responses": [{"respondent_id": 12, "response": "String"}, ...],
# }, {
# 	"question": "string", 
#   "responses": [{"respondent_id": 12, "response": "String"}, ...],
# }]
# 
var chosen_questions: Array
var _is_goto_state: bool = false

# used to track whether the timer has run out or not. If it has, need to stop taking responses
# and move to next stage
var _time_up: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#all sorts of connections
	_room_manager = _quiplash_room_manager._room_manager
	_quiplash_room_manager.received_packet.connect(_on_received_packet)
	_room_manager.game_started.connect(_on_game_start)
	_room_manager.game_ended.connect(_on_game_end)
	visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#calls the update function from the active state, if it exists
	#basically lets the states use the manager's process function.
	if (not (_active_state == null)):
		_active_state.update(delta)

func _on_received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer):
	#forwards all packets to the active state, lets it process the packet in its own way
	if (not (_active_state == null)):
		_active_state.received_packet(sender_id, packet_id, buffer)

func _go_to_state(state: int):
	if _is_goto_state:
		LimboConsole.print_lineerr("Already transitioning to state")
		return
	_is_goto_state = true
	#tell players that the state is changing
	_quiplash_room_manager.host_change_state(state)
	
	#search through children
	#get STATE_NUM from child, see if it matches state
	#if it does, activate it.
	for child: Node in get_children():
		if "STATE_NUM" in child:
			var is_active = child.STATE_NUM == state
			if is_active:
				#exit previous state, set state to active state, enter state
				if (not (_active_state == null)):
					_active_state.exit()
				_active_state = child
				_active_state.enter()
				#start host timer and start all player timers
				_host_timer.start_timer(_active_state.STATE_DURATION)
				#if (state == States.SCORING):
				_host_timer.visible = true
				_quiplash_room_manager.host_start_timer(_active_state.STATE_DURATION)
			child.visible = is_active
	_is_goto_state = false

#reads all questions from the questions_list file and adds them to an array
func _read_questions():
	var questions_file = FileAccess.open("res://room_games/quiplash/assets/questions_list.txt", FileAccess.READ)
	while (questions_file.get_position() < questions_file.get_length()):
		all_question_queue.push_back(questions_file.get_line())
	questions_file.close()
	all_question_queue.shuffle()

# Pops a new question from the all_questions queue
# Adds the new question to the chosen_questions list,
# and returns the chosen question string.
func get_new_question() -> Dictionary:
	if len(all_question_queue) == 0:
		LimboConsole.print_lineerr("all_question_queue is empty! Not enough questions")
		return {}
	var question_data = {
		"question": all_question_queue.pop_back(),
		"index": len(chosen_questions),
		"responses": []
	}
	chosen_questions.push_back(question_data)
	return question_data

func _on_game_start():
	#get all players, add them to a dictionary with some information about them
	#refer to sample somewhere above
	for key in _room_manager.players:
		_player_data[key] = {
			"username": _room_manager.players[key],
			"score": 0,
			"answered_questions": 0,
			"voted": false,
			"question_ids": [],
		}
	
	#every player will answer two questions, but every question gets sent to two players
	questions_needed = _player_data.size()
	
	#load questions
	_read_questions()
	_go_to_state(States.QUESTIONS)
	visible = true

func hide_timer():
	_host_timer.visible = false

func _timer_up():
	#what happens when we run out of time?
	
	#handle any timer ups outside of states here?
	
	if (_active_state == null):
		return

	if _active_state.STATE_NUM == States.QUESTIONS:
		prompting_finished()
		return
	
	if _active_state.STATE_NUM == States.VOTING:
		voting_finished()
		return
	
	if _active_state.STATE_NUM == States.SCORING:
		scoring_finished()
		return

func prompting_finished():
	#step one - remove questions with empty responses
	var index = 0
	while (index < len(chosen_questions)):
		var allEmpty = true
		for player_response in chosen_questions[index]["responses"]:
			if len(player_response["response"]) > 0:
				allEmpty = false
				break
		if allEmpty:
			chosen_questions.remove_at(index)
		else:
			index += 1
	
	_go_to_state(States.VOTING)

func voting_finished():
	_active_state.update_and_score()

	if (len(chosen_questions) > 0):
		_go_to_state(States.VOTING)
	else:
		_go_to_state(States.SCORING)
	for i in _player_data:
		LimboConsole.print_line(str(_player_data[i]["username"]))
		LimboConsole.print_line(str(_player_data[i]["score"]))

func scoring_finished():
	_go_to_state(States.QUESTIONS)
	
func print_questions():
	for question in chosen_questions:
		LimboConsole.print_line(str(question["question"]))
		for question_response in question["responses"]:
			LimboConsole.print_line(str(question_response))

func _on_game_end():
	pass
