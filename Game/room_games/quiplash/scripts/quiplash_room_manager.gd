class_name QuiplashRoomManager
extends GameRoomManager


signal received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer)
@export var _host_manager: QuiplashHostManager
@export var _player_manager: QuiplashPlayerManager

enum PacketID {
	# HOST PACKETS
	HOST_CHANGE_STATE = 1,
	HOST_SEND_QUESTIONS = 2,
	HOST_START_ROUND = 3,
	HOST_START_TIMER = 4,
	HOST_SEND_VOTE_QUESTION = 5,
	HOST_END_GAME = 6,
	
	# PLAYER PACKETS
	PLAYER_SEND_RESPONSE = 128,
	PlAYER_SEND_VOTE = 129
}


func _enter_tree() -> void:
	#might this cause problems?
	if not _room_manager.is_host:
		_host_manager.queue_free()
	else:
		_player_manager.queue_free()


func _ready() -> void:
	LimboConsole.print_line("Quiplash initialized!")


func _game_started():
	LimboConsole.print_line("Quiplash game started!")


func _game_ended():
	LimboConsole.print_line("Quiplash game ended!")
	_room_manager.players


func _on_received_game_packet(sender_id: int, buffer: ByteBuffer):
	var packet_id = buffer.get_u8()
	received_packet.emit(sender_id, packet_id, buffer)


func host_change_state(state_id: int):
	_packet_buffer.clear()
	_packet_buffer.put_u8(PacketID.HOST_CHANGE_STATE)
	_packet_buffer.put_u8(state_id)
	send_to_all_players(_packet_buffer.data_array)


# questions = [{
#	id: 1
#	text: "What is 10 + 11?"
# }]
func host_send_questions_to_player(player_id: int, questions: Array):
	_packet_buffer.clear()
	_packet_buffer.put_u8(PacketID.HOST_SEND_QUESTIONS)
	_packet_buffer.put_u8(len(questions))
	for question in questions:
		_packet_buffer.put_u8(question.id)
		_packet_buffer.put_utf8_string(question.text)
	send_to_player(_packet_buffer.data_array, player_id)

func host_start_new_round():
	LimboConsole.print_line("		begin host_start_new_round()")
	_packet_buffer.clear()
	_packet_buffer.put_u8(PacketID.HOST_START_ROUND)
	send_to_all_players(_packet_buffer.data_array)
	LimboConsole.print_line("		finish host_start_new_round()")

func host_start_timer(duration: int):
	_packet_buffer.clear()
	_packet_buffer.put_u8(PacketID.HOST_START_TIMER)
	_packet_buffer.put_u8(duration)
	send_to_all_players(_packet_buffer.data_array)

func host_send_vote_question(question: Dictionary):
	_packet_buffer.clear()
	_packet_buffer.put_u8(PacketID.HOST_SEND_VOTE_QUESTION)
	_packet_buffer.put_utf8_string(question["question"])
	_packet_buffer.put_u8(len(question["responses"]))
	for player_response in question["responses"]:
		_packet_buffer.put_u32(player_response["respondent_id"])
		_packet_buffer.put_utf8_string(player_response["response"])
	send_to_all_players(_packet_buffer.data_array)

func host_end_game():
	_packet_buffer.clear()
	_packet_buffer.put_u8(PacketID.HOST_END_GAME)
	send_to_all_players(_packet_buffer.data_array)

func player_send_response(question_id: int, response: String):
	_packet_buffer.clear()
	_packet_buffer.put_u8(PacketID.PLAYER_SEND_RESPONSE)
	_packet_buffer.put_u8(question_id)
	_packet_buffer.put_utf8_string(response)
	send_to_host(_packet_buffer.data_array)
	
func player_send_vote(chosen_id: int):
	_packet_buffer.clear()
	_packet_buffer.put_u8(PacketID.PlAYER_SEND_VOTE)
	_packet_buffer.put_u32(chosen_id)
	send_to_host(_packet_buffer.data_array)
