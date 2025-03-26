class_name QuiplashRoomManager
extends GameRoomManager


signal received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer)
@export var _host_manager: QuiplashHostManager
@export var _player_manager: QuiplashPlayerManager

enum PacketID {
	# HOST PACKETS
	HOST_SEND_HI = 0,
	HOST_CHANGE_STATE = 1,
	HOST_SEND_QUESTION = 2
	
	# PLAYER PACKETS
	
}

func _enter_tree() -> void:
	#might this cause problems?
	if not _room_manager.is_host:
		_host_manager.queue_free()
	else:
		_player_manager.queue_free()


func _ready() -> void:
	print("Quiplash initialized!")



func _game_started():
	print("Quiplash game started!")
	if _room_manager.is_host:
		_host_send_hi()


func _game_ended():
	print("Quiplash game ended!")


func _on_received_game_packet(sender_id: int, buffer: ByteBuffer):
	var packet_id = buffer.get_u8()
	received_packet.emit(sender_id, packet_id, buffer)
	if packet_id == PacketID.HOST_SEND_HI:
		print("RECEIVED HI!")

func _host_send_hi():
	_packet_buffer.clear()
	_packet_buffer.put_u8(PacketID.HOST_SEND_HI)
	print("SENDING HI!")
	send_to_all_players(_packet_buffer.data_array)

func _host_change_phase(state_id: int):
	_packet_buffer.clear()
	_packet_buffer.put_u8(PacketID.HOST_CHANGE_STATE)
	_packet_buffer.put_u8(state_id)
	send_to_all_players(_packet_buffer.data_array)

func _send_question_to_player(player_id: int, question_id: int, question: String):
	_packet_buffer.clear()
	_packet_buffer.put_u8(PacketID.HOST_SEND_QUESTION)
	_packet_buffer.put_u8(question_id)
	_packet_buffer.put_string(question)
	send_to_player(_packet_buffer, player_id)
