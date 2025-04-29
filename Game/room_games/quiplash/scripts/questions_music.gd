extends QuiplashAudioBaseState

func _ready() -> void:
	MUSIC_NUM = MUSIC.QUESTIONS
	_original_volume = volume_db
