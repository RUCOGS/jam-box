class_name QuiplashPlayerManager
extends Control

@export var _quiplash_room_manager: QuiplashRoomManager
var _room_manager: RoomManager
var _active_state: QuiplashBaseState

enum States {
	QUESTIONS = 1,
	VOTING = 2,
	SCORING = 3
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_room_manager = _quiplash_room_manager._room_manager
	_quiplash_room_manager.received_packet.connect(_on_received_packet)
	_room_manager.game_started.connect(_on_game_start)
	_room_manager.game_ended.connect(_on_game_end)
	visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (not (_active_state == null)):
		_active_state.update(delta)


func _on_received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer):
	
	#Host Change State
	if (packet_id == _quiplash_room_manager.PacketID.HOST_CHANGE_STATE):
		_go_to_state(buffer.get_u8())

	if (not (_active_state == null)):
		_active_state.received_packet(sender_id, packet_id, buffer)

func _go_to_state(state: int):
	#search through children
	#get STATE_NUM from child, see if it matches state
	#if it does, activate it.
	for child: Node in get_children():
		if "STATE_NUM" in child and child.STATE_NUM == state:
			#exit previous state, set state to active state, enter state, break
			if (not (_active_state == null)):
				_active_state.exit()
			_active_state = child
			_active_state.enter()
			break

func _on_game_start():
	visible = true

func _on_game_end():
	pass
