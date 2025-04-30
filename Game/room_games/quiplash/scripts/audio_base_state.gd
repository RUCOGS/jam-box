class_name QuiplashAudioBaseState
extends AudioStreamPlayer


var _original_volume: float
var _tween: Tween
var MUSIC_NUM: int

var isActive: bool = false

enum MUSIC {
	QUESTIONS = 1,
	VOTING = 2,
	SCORING = 3
}

func _ready() -> void:
	pass

func exit():
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "volume_db", -80, 3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func enter():
	if _tween:
		_tween.kill()
	_tween = create_tween()
	print(_original_volume)
	_tween.tween_property(self, "volume_db", _original_volume, 3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
