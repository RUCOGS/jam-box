extends QuiplashBaseState

@export var _quiplash_host_manager: QuiplashHostManager
@export var _quiplash_room_manager: QuiplashRoomManager

var _current_question: Dictionary

func _ready() -> void:
	STATE_NUM = States.VOTING
	STATE_DURATION = Duration.VOTING

func received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer):
	if packet_id == _quiplash_room_manager.PacketID.HOST_SEND_VOTE_QUESTION:
		_current_question = {
			"question": buffer.get_string(),
			"responses": []
		}
		var num_responses = buffer.get_u8()
		for i in range(num_responses):
			var player_id = buffer.get_u8()
			var player_response = buffer.get_string()
			_current_question["responses"].append({
				"respondent_id": player_id,
				"response": player_response
			})

#when the state is first entered.
func enter():
	pass
	
#when the state is exited (called before the next state is entered)
func exit():
	pass

#called every frame in the manager
func update(_delta: float):
	pass
