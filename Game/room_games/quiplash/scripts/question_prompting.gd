extends QuiplashBaseState

@export var _quiplash_host_manager: QuiplashHostManager
@export var _quiplash_room_manager: QuiplashRoomManager

#this was just a test to make sure that the states were actually changing
#can probably be removed
var thingamabob = "Host State Questions Started"

#dict of players
var _players: Dictionary

#array of questions
var _questions: Array

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	STATE_NUM = States.QUESTIONS

func received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer):
	pass

#overwrite base update
func update(_delta: float):
	pass
	
#overwrite base enter
func enter():
	#update players and chosen questions
	_players = _quiplash_host_manager._player_data
	_questions = _quiplash_host_manager.chosen_questions
	
	#distribute questions -- first question goes to first two players, second goes to next to...
	#... and so on
	
	#temporary player index
	var p_index = 0
	for _player_id in _players:
		#send two questions to each player
		var q_index = p_index
		_quiplash_room_manager.send_question_to_player(int(_player_id), q_index, _questions[q_index]["question"])
		print("Question sent!")
		q_index += 1
		if (q_index == _questions.size()):
			q_index = 0
		_quiplash_room_manager.send_question_to_player(int(_player_id), q_index, _questions[q_index]["question"])
		print("Question sent!")
		p_index += 1
