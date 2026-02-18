class_name CoggleRoomManager
extends GameRoomManager


signal received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer)
@export var _host_manager: CoggleHostManager
@export var _player_manager: CogglePlayerManager

enum PacketID {
	# HOST PACKETS (Start from 1, go up++)
	HOST_CHANGE_STATE = 1,
	
	# PLAYER PACKETS (Start from 129, go down--)
	PlAYER_SEND_VOTE = 129
}


func _enter_tree() -> void:
	if not _room_manager.is_host:
		_host_manager.queue_free()
	else:
		_player_manager.queue_free()


func _ready() -> void:
	LimboConsole.print_line("Coggle initialized!")


func _game_started():
	LimboConsole.print_line("Coggle game started!")


func _game_ended():
	LimboConsole.print_line("Coggle game ended!")
	#_room_manager.players


func _on_received_game_packet(sender_id: int, buffer: ByteBuffer):
	var packet_id = buffer.get_u8()
	received_packet.emit(sender_id, packet_id, buffer)


#preserving one function each from host and player for quick reference
#func host_change_state(state_id: int):
	#_packet_buffer.clear()
	#_packet_buffer.put_u8(PacketID.HOST_CHANGE_STATE)
	#_packet_buffer.put_u8(state_id)
	#send_to_all_players(_packet_buffer.data_array)
#
#func player_send_vote(chosen_id: int):
	#_packet_buffer.clear()
	#_packet_buffer.put_u8(PacketID.PlAYER_SEND_VOTE)
	#_packet_buffer.put_u32(chosen_id)
	#send_to_host(_packet_buffer.data_array)
