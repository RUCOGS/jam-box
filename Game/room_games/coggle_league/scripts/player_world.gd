class_name PlayerWorld
extends Node2D

@export var _player_manager: CogglePlayerManager
@export var _player_border: StaticBody2D
@export var _player_character_prefab: PackedScene

var _bounding_rect: Rect2
var _game_scale: float
var _char_array: Array[PlayerCharacter]

func _ready() -> void:
	_player_border.scale = Vector2(1,1)

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
	_player_border.update_game_size(_bounding_rect, _game_scale)

#used to add characters to the player's screen
func spawn_player_character(location: Vector2, controllable: bool):
	var _player_char_instance: PlayerCharacter = _player_character_prefab.instantiate()
	_player_char_instance.player_construct(_char_array.size(), location, controllable, 2)
	_char_array.append(_player_char_instance)
	self.add_child(_player_char_instance)
	
func game_start():
	spawn_player_character(Vector2(400,400), true)

func _unhandled_input(event: InputEvent) -> void:
	# Check for a left mouse button click release
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed == true:
		print("clicked player world!")
		#get_viewport().set_input_as_handled()
	
