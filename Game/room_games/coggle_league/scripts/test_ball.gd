class_name ball
extends RigidBody2D

@export var _ball_collider: CollisionShape2D
@export var sprites: Node2D
var _friction: float
var _moving: bool = false
var _target_vector: Vector2

func _ready() -> void:
	scale = Vector2(1,1)

func ball_construct(size_scale: int, location: Vector2, vel: Vector2, fric: float):
	_friction = fric
	move_to(location, vel)
	_set_size(size_scale)
	

func move_to(location: Vector2, velocity: Vector2):
	_target_vector = location
	linear_velocity = velocity
	_moving = true

func _set_size(target_scale: int):
	sprites.scale *= target_scale
	_ball_collider.shape.radius = 10 * target_scale
	mass *= target_scale ** 2

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _moving:
		state.transform.origin = _target_vector
		_moving = false
	#_apply_friction()

func _apply_friction():
	var _friction_direction = (linear_velocity * -1).normalized()
	apply_central_force(_friction_direction * _friction * mass)
