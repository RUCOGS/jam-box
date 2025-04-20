extends QuiplashBaseState

@export var _quiplash_player_manager: QuiplashPlayerManager
@export var _quiplash_room_manager: QuiplashRoomManager

@export var _voting_panel: PanelContainer
@export var _waiting_panel: PanelContainer
@export var _question_label: Label
@export var _answer_button_1: Button
@export var _answer_button_2: Button

var _current_question: Dictionary

func _ready() -> void:
	STATE_NUM = States.VOTING
	_answer_button_1.pressed.connect(_button1_pressed)
	_answer_button_2.pressed.connect(_button2_pressed)
	

func received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer):
	if packet_id == _quiplash_room_manager.PacketID.HOST_SEND_VOTE_QUESTION:
		_current_question = {
			"question": buffer.get_string(),
			"responses": []
		}
		var num_responses = buffer.get_u8()
		for i in range(num_responses):
			var player_id = buffer.get_u32()
			var player_response = buffer.get_string()
			_current_question["responses"].append({
				"respondent_id": player_id,
				"response": player_response
			})
		_question_label.text = _current_question["question"]
		var response1 = _current_question["responses"][0]["response"]
		var response2 = _current_question["responses"][1]["response"]
		_answer_button_1.text = response1 if len(response1) > 0 else "No Response Given"
		_answer_button_2.text = response2 if len(response2) > 0 else "No Response Given"

#when the state is first entered.
func enter():
	_waiting_panel.visible = false
	_voting_panel.visible = true
	_question_label.text = "Loading..."
	_answer_button_1.text = "Loading..."
	_answer_button_2.text = "Loading..."

#when the state is exited (called before the next state is entered)
func exit():
	pass

#called every frame in the manager
func update(_delta: float):
	pass

func _button1_pressed():
	_quiplash_room_manager.player_send_vote(_current_question["responses"][0]["respondent_id"])
	_waiting_panel.visible = true
	_voting_panel.visible = false
	_quiplash_player_manager.hide_timer()

func _button2_pressed():
	_quiplash_room_manager.player_send_vote(_current_question["responses"][1]["respondent_id"])
	_waiting_panel.visible = true
	_voting_panel.visible = false
	_quiplash_player_manager.hide_timer()
