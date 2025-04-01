extends QuiplashBaseState

@export var _quiplash_host_manager: QuiplashHostManager
@export var _quiplash_room_manager: QuiplashRoomManager

var thingamabob = "Host State Questions Started"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	STATE_NUM = States.QUESTIONS

func received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer):
	pass

#overwrite parent update
func update(_delta: float):
	pass
	
#overwrite parent enter
func enter():
	pass
