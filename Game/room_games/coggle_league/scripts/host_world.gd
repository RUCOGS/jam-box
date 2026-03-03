class_name HostWorld
extends Node2D


@export var _host_manager: CoggleHostManager
@export var _game_borders: StaticBody2D
@export var _test_ball_prefab: PackedScene
var _bounding_rect: Rect2
var _game_scale: float

var _friction: float = 0

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

func update_bounding_rect(viewport: Vector2i):
	_bounding_rect.size = 0.8 * viewport
	_bounding_rect.position.x = viewport.x * 0.1
	_bounding_rect.position.y = 0
	
	#Scale of the game, impacts size of characters and whatnot.
	#400 is the size of the default board
	_game_scale = 	_bounding_rect.size.x / 400
	_game_borders.update_game_size(_bounding_rect, _game_scale)
	
	
	#this is for testing, remove this later.
	#once everything is set up send a signal somewhere to start the game.
	_spawn_ball(1, Vector2(200,200), Vector2(1500,0))

func _spawn_ball(size_scale: int, location: Vector2, vel: Vector2):
	var _ball_instance: ball = _test_ball_prefab.instantiate()
	self.add_child(_ball_instance)
	_ball_instance.ball_construct(size_scale, location, vel, _friction)
