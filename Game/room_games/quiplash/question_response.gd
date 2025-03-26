extends QuiplashBaseState

@export var _quiplash_host_manager: QuiplashPlayerManager

var thingamabob = "Player State Started"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	STATE_NUM = States.QUESTIONS

func received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer):
	pass
