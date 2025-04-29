class_name QuiplashBaseState
extends Control


#NOTE: This script is used for both player and host states. Hopefully that doesn't cause problems
var STATE_NUM: int
@export var STATE_DURATION: int = 10
var isActive: bool = false
enum States {
	QUESTIONS = 1,
	VOTING = 2,
	SCORING = 3
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

#when the state is first entered.
func enter():
	pass

#when the state is exited (called before the next state is entered)
func exit():
	pass

#called every frame in the manager
func update(_delta: float):
	pass

#process received packets
func received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer):
	pass
