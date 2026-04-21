extends StaticBody2D

@export var _collider: CollisionShape2D
@export var _player_visuals: Node2D

func _ready() -> void:
	_collider.scale = Vector2(1,1)
	_player_visuals.scale = Vector2(1,1)

func update_game_size(rect: Rect2, input_scale: float):
	_collider.scale *= input_scale
	_player_visuals.scale *= input_scale
	
	position = rect.position + rect.size / 2
