class_name HostWorld
extends Node2D


@export var _host_manager: CoggleHostManager
@export var _game_borders: StaticBody2D
@export var _test_ball_prefab: PackedScene
var _bounding_rect: Rect2
var _game_scale: float

var _friction: float = 100

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

func received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer):
	#handle packets here
	pass

func update_bounding_rect(viewport: Vector2i):
	_bounding_rect.size = 0.8 * viewport
	_bounding_rect.position.x = viewport.x * 0.1
	_bounding_rect.position.y = 0
	
	#Scale of the game, impacts size of characters and whatnot.
	#400 is the size of the default board
	_game_scale = 	_bounding_rect.size.x / 400
	_game_borders.update_game_size(_bounding_rect, _game_scale)

func _spawn_ball(size_scale: int, location: Vector2, vel: Vector2):
	var _ball_instance: ball = _test_ball_prefab.instantiate()
	self.add_child(_ball_instance)
	_ball_instance.ball_construct(size_scale, location, vel, _friction)

func game_start():
	#note -- use relative spawn locations (i.e. bounding_rect.x * 0.2 or something)
	_spawn_ball(1, Vector2(600,200), Vector2(0,0))
	_spawn_ball(2, Vector2(200,200), Vector2(0,0))
