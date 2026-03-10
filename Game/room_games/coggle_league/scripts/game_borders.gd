extends StaticBody2D

@export var _collider: CollisionPolygon2D
@export var _visual_board: Node2D

#Prevent railgun shots from blasting past the borders
@export var _border_array: Array[CollisionShape2D]
@export var _corner_array: Array[CollisionShape2D]

#Populate a default parameters array
#some values carry over for some reason
var _default_border_distances: Array[float] = [-100.0, -100.0, -200.0, -200.0]
var _default_corner_positions: Array[Vector2] = [Vector2(-187.5, -75), Vector2(187.5, -75), Vector2(-187.5, 75), Vector2(187.5, 75)]


func _ready() -> void:
	_collider.scale = Vector2(1,1)
	_visual_board.scale = Vector2(1,1)
	for i in range(_border_array.size()):
		_border_array[i].shape.distance = _default_border_distances[i]
	for j in range(_corner_array.size()):
		_corner_array[j].position = _default_corner_positions[j]
		_corner_array[j].shape.size = Vector2(25,50)

func update_game_size(rect: Rect2, input_scale: float):
	_collider.scale *= input_scale
	_visual_board.scale *= input_scale
	for i in range(_border_array.size()):
		_border_array[i].shape.distance *= input_scale
	for j in range(_corner_array.size()):
		_corner_array[j].position *= input_scale
		_corner_array[j].shape.size *= input_scale
	
	position = rect.position + rect.size / 2
