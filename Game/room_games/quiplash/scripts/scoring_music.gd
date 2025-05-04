extends QuiplashAudioBaseState

func _ready() -> void:
	MUSIC_NUM = MUSIC.SCORING
	_original_volume = volume_db - 10
	volume_db = -80
