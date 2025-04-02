extends QuiplashBaseState

@export var _quiplash_player_manager: QuiplashPlayerManager
@export var _quiplash_room_manager: QuiplashRoomManager

@export var _question_label: Label
@export var _question_text_edit: Label

#list of questions to be answered this round, holds dictionaries
# [{
#	"id": 3,
#	"text": "what color is the sky"
#}]
var _questions_to_answer: Array

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	STATE_NUM = States.QUESTIONS

func received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer):
	#clears the questions at the start of the round
	if (packet_id == _quiplash_room_manager.PacketID.HOST_START_ROUND):
		_questions_to_answer.clear()
	if (packet_id == _quiplash_room_manager.PacketID.HOST_SEND_QUESTION):
		print("Question Received!")
		var question_id = buffer.get_u8()
		var question_text = buffer.get_string()
		var question_dict = {
			"id": question_id,
			"text": question_text
		}
		_questions_to_answer.append(_questions_to_answer)
		
		#Important! Need a way to get the id somehow...? This isn't working.
		print(str(_quiplash_room_manager.id) + " " + question_text)

#overwrite base update
func update(_delta: float):
	pass
	
#overwrite base enter
func enter():
	pass
