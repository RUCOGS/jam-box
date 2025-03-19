class_name QuiplashBaseState
extends Node

var STATE_NUM
var isActive: bool = false
enum States {
	PROMPTING_QUESTIONS = 1,
	VOTING = 2,
	SCORING = 3
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func enter():
	pass
	
func exit():
	pass

func update(_delta: float):
	pass
	
func received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer):
	pass
