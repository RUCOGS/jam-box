class_name QuiplashAudioManager
extends Control

@export var _quiplash_room_manager: QuiplashRoomManager
@export var _quiplash_host_manager: QuiplashHostManager
var _room_manager: RoomManager
var _music_changing: bool
var _active_music: QuiplashAudioBaseState

func _ready() -> void:
	_room_manager = _quiplash_room_manager._room_manager
	_room_manager.game_ended.connect(_on_game_end)

func go_to_state(state: int):
	if _music_changing:
		printerr("Already transitioning music")
		return
	_music_changing = true
	
	#if it does, activate it.
	for child: Node in get_children():
		if "STATE_NUM" in child:
			var is_active = child.MUSIC_NUM == state
			if is_active:
				#exit previous state, set state to active state, enter state
				if (not (_active_music == null)):
					_active_music.exit()
				_active_music = child
				_active_music.enter()
			child.visible = is_active
	_music_changing = false

func _on_game_end():
	pass
	#stop everything
