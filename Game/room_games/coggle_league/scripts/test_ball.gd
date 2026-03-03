class_name ball
extends RigidBody2D

@export var _ball_collider: CollisionShape2D
@export var sprites: Node2D
var _friction: float

func _ready() -> void:
	scale = Vector2(1,1)

func ball_construct(size_scale: int, location: Vector2, vel: Vector2, fric: float):
	_friction = fric
	move_to(location, vel)
	sprites.scale *= size_scale
	_ball_collider.shape.radius = 10 * size_scale
	

func move_to(location: Vector2, velocity: Vector2):
	print("recieved")
	global_position = location
	linear_velocity = velocity

func set_size(collider_scale: int):
	pass

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	_apply_friction()

func _apply_friction():
	var _friction_direction = (linear_velocity * -1).normalized()
	apply_central_force(_friction_direction * _friction * mass)
