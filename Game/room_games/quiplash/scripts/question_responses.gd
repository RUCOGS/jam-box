extends QuiplashBaseState


@export var _quiplash_player_manager: QuiplashPlayerManager
@export var _quiplash_room_manager: QuiplashRoomManager

@export var _question_label: Label
@export var _question_text_edit: TextEdit
@export var _submit_button: Button
@export var _question_panel: PanelContainer
@export var _waiting_panel: PanelContainer

# List of questions to be answered this round, holds dictionaries
# [{
#	"id": 3,
#	"text": "what color is the sky"
# 	"response": ""
#}]
var _questions_to_answer: Array[Dictionary]
# Current question we are on
var _current_question_id: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	STATE_NUM = States.QUESTIONS
	_submit_button.pressed.connect(_on_submit_pressed)
	_question_text_edit.text_changed.connect(_update_button)


func received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer):
	#clears the questions at the start of the round
	if (packet_id == _quiplash_room_manager.PacketID.HOST_START_ROUND):
		_questions_to_answer.clear()
	if (packet_id == _quiplash_room_manager.PacketID.HOST_SEND_QUESTIONS):
		LimboConsole.print_line("Questions Received!")
		var question_count = buffer.get_u8()
		for i in range(question_count):
			var question_id = buffer.get_u8()
			var question_text = buffer.get_utf8_string()
			_questions_to_answer.append({
				"id": question_id,
				"text": question_text
			})
		_current_question_id = 0
		_update_question()
		_question_panel.visible = true


func _update_question():
	_question_label.text = _questions_to_answer[_current_question_id]["text"]
	_question_text_edit.text = ""
	_submit_button.text = "Submit (%s/%s)" % [_current_question_id + 1, len(_questions_to_answer)]
	_update_button()


func _on_submit_pressed():
	if _current_question_id >= len(_questions_to_answer):
		return
	var response_text = _question_text_edit.text.strip_edges()
	# Response must be >= 1 character
	if len(response_text) <= 0:
		return
	var curr_question = _questions_to_answer[_current_question_id]
	curr_question["response"] = response_text
	_current_question_id += 1
	# Send response
	_quiplash_room_manager.player_send_response(curr_question["id"], curr_question["response"])
	if _current_question_id < len(_questions_to_answer):
		_update_question()
	else:
		# transition to waiting
		_waiting_panel.visible = true
		_question_panel.visible = false
		return

# Overwrite base update
func update(_delta: float):
	pass


# Overwrite base enter
func enter():
	_waiting_panel.visible = false
	_question_panel.visible = false

func exit():
	pass

func _update_button():
	LimboConsole.print_line("question_text_edit text: '%s'" % [_question_text_edit.get_text()])
	_submit_button.disabled = false # len(_question_text_edit.get_text()) <= 0
