class_name QuiplashHostManager
extends Control

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
#number of questions needed
@export var questions_needed: int

# dict of question data:
# "question": "string", 
# "responses": [{"respondent_id": 12, "response": "String"}, ...],
# 
# 
var chosen_questions: Array

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#all sorts of connections
	_room_manager = _quiplash_room_manager._room_manager
	_quiplash_room_manager.received_packet.connect(_on_received_packet)
	_room_manager.game_started.connect(_on_game_start)
	_room_manager.game_ended.connect(_on_game_end)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#calls the update function from the active state, if it exists
	#basically lets the states use the manager's process function.
	if (not (_active_state == null)):
		_active_state.update(delta)

func _on_received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer):
	#forwards all packets to the active state, lets it process the pcaket in its own way
	if (not (_active_state == null)):
		_active_state.received_packet(sender_id, packet_id, buffer)

func _go_to_state(state: int):
	#tell players that the state is changing
	_quiplash_room_manager.host_change_state(state)
	
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



#reads all questions from the questions_list file and adds them to an array
func _read_questions():
	var questions_file = FileAccess.open("res://room_games/quiplash/assets/questions_list.txt", FileAccess.READ)
	while (questions_file.get_position() < questions_file.get_length()):
		_all_questions.push_back(questions_file.get_line())
	questions_file.close()


#randomizes and chooses the needed amount of questions
func _choose_questions(num_questions):
	_all_questions.shuffle()
	for i in num_questions:
		#in case there's not enough questions...
		var _current_question = "uh oh"
		
		#otherwise, pick a question from a shuffled list
		if (i < _all_questions.size()):
			_current_question = _all_questions[i]
		var question_dict = {
			"question": _current_question,
			"responses": []
		}
		
		#add them to an already made chosen_questions array
		chosen_questions.push_back(question_dict)
	
func _on_game_start():
	#get all players, add them to a dictionary with some information about them
	#refer to sample somewhere above
	for key in _room_manager.players:
		_player_data[key] = {
			"username": _room_manager.players[key],
			"score": 0,
			"responded": false
		}
	
	#every player will answer two questions, but every question gets sent to two players
	questions_needed = _player_data.size()
	
	#get the questions, choose 'em, and start the game
	_read_questions()
	_choose_questions(questions_needed)
	_go_to_state(States.QUESTIONS)

func _on_game_end():
	pass
