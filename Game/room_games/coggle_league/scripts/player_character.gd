class_name PlayerCharacter
extends Node2D

@export var _sprite_base: Sprite2D
@export var _projectile_path: Line2D
@export var _highlight: Sprite2D
@export var _click_detector: Area2D
@export var _click_detector_collider: CollisionShape2D

var _char_id: int
var controllable: bool
signal selected(id: int)
signal power_update(power: float)

#constructor
#set id to be used in signaling
func player_construct(id: int, location: Vector2, control: bool, size_scale: float):
	scale = Vector2(1,1)
	_char_id = id
	position = location
	controllable = control
	scale *= size_scale

#when interacted with: 
func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Tell the engine to stop propagating this input event (it won't reach _unhandled_input)
		get_viewport().set_input_as_handled()
		# Update selected object here + other selection logic
		print("Picked " + str(_char_id) + "!")
	
		#get_tree().current_scene.selected_object = self


func deselect():
	# Deselecting, run from PlayerWorld
	print("Clicked away from object, deselecting.")
	
	pass # Replace with function body.


#updating power arrow:
#if selected to move -- show arrow
#Scale all points line based on how much power is put into the shot
	#multiply each x value in packed array by a value from 0 to 1. (0% to 100%)

#func get power
