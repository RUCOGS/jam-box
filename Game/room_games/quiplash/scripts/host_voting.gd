extends QuiplashBaseState

@export var _quiplash_host_manager: QuiplashHostManager
@export var _quiplash_room_manager: QuiplashRoomManager

@export var _voting_question_label: Label
@export var _voting_option_1: Label
@export var _voting_option_2: Label
@export var _vote_bar: ProgressBar

var _current_question: Dictionary
var _players_responded: int
var _total_players: int
var _response_1_votes: int
var _response_2_votes: int

func _ready() -> void:
	STATE_NUM = States.VOTING

func received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer):
	if packet_id == _quiplash_room_manager.PacketID.PlAYER_SEND_VOTE:
		_players_responded += 1
		var respondent_id = buffer.get_u32()
		if respondent_id == _current_question["responses"][0]["respondent_id"]:
			_response_1_votes += 1
		else:
			_response_2_votes += 1
		_update_bar()
		if _players_responded >= _total_players:
			_quiplash_host_manager.voting_finished()

#when the state is first entered.
func enter():
	_current_question = _quiplash_host_manager.chosen_questions.pop_front()
	_quiplash_room_manager.host_send_vote_question(_current_question)
	_vote_bar.value = 50
	_response_1_votes = 0
	_response_2_votes = 0
	_players_responded = 0
	_total_players = _quiplash_host_manager._player_data.size()
	_voting_question_label.text = _current_question["question"]
	assert(len(_current_question["responses"]) == 2, "Error: # of responses != 2")
	var response1 = _current_question["responses"][0]["response"]
	var response2 = _current_question["responses"][1]["response"]
	_voting_option_1.text = response1 if len(response1) > 0 else "No Response Given"
	_voting_option_2.text = response2 if len(response2) > 0 else "No Response Given"

#when the state is exited (called before the next state is entered)
func exit():
	pass

#called every frame in the manager
func update(_delta: float):
	pass

func update_and_score():
	if (_response_1_votes + _response_2_votes > 0):
		_quiplash_host_manager._player_data[_current_question["responses"][0]["respondent_id"]]["score"] += (_response_1_votes * 500) / (_response_1_votes + _response_2_votes)
		_quiplash_host_manager._player_data[_current_question["responses"][1]["respondent_id"]]["score"] += (_response_2_votes * 500) / (_response_1_votes + _response_2_votes)
	

func _update_bar():
	var progress_value = (_response_1_votes * 100.0) / (_response_1_votes + _response_2_votes)
	_vote_bar.value = progress_value
