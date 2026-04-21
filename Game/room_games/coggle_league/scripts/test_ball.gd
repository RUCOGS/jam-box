class_name ball
extends RigidBody2D

@export var _ball_collider: CollisionShape2D
@export var sprites: Node2D
var _friction: float
var _instant_moving: bool = false
var _target_vector: Vector2

#Spawning into a collider even though I changed initial position.
# I'll manually reset it the first time.
var _spawn_reset: bool = true


func _ready() -> void:
	scale = Vector2(1,1)

func ball_construct(size_scale: float, location: Vector2, vel: Vector2, fric: float):
	_friction = fric
	move_to(location, vel)
	_set_size(size_scale)

func move_to(location: Vector2, velocity: Vector2):
	_target_vector = location
	_instant_moving = true

func _set_size(target_scale: float):
	scale = Vector2(1,1)
	sprites.scale = Vector2(1,1)
	
	sprites.scale *= target_scale
	_ball_collider.shape.radius = 10 * target_scale
	mass *= target_scale ** 2

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _instant_moving:
		state.transform.origin = _target_vector
		_instant_moving = false
	if _spawn_reset and not state.transform.origin == _target_vector:
		_spawn_reset = false
		state.transform.origin = _target_vector
	_apply_friction()
	
func _apply_friction():
	var _friction_direction = (linear_velocity * -1).normalized()
	apply_central_force(_friction_direction * _friction * mass)
