class_name QuiplashRoomManager
extends GameRoomManager


signal received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer)


enum PacketID {
	# HOST PACKETS
	HOST_SEND_HI = 0
	
	# PLAYER PACKETS
}


func _ready() -> void:
	print("Quiplash initialized!")
	if !_room_manager.is_host:
		$HostManager.queue_free()


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
