extends AudioStreamPlayer


@export var _room_manager: RoomManager

var _original_volume: float
var _tween: Tween


func _ready() -> void:
	_room_manager.game_started.connect(_on_game_started)
	_room_manager.game_ended.connect(_on_game_ended)
	_original_volume = volume_db


func _on_game_started():
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "volume_db", -80, 3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _on_game_ended():
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "volume_db", _original_volume, 3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
