extends StaticBody2D

@export var _collider: CollisionPolygon2D
@export var _visual_board: Node2D

func _ready() -> void:
	_collider.scale = Vector2(1,1)
	_visual_board.scale = Vector2(1,1)

func update_game_size(rect: Rect2, input_scale: float):
	_collider.scale *= input_scale
	_visual_board.scale *= input_scale
	position = rect.position + rect.size / 2
