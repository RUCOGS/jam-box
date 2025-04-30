extends QuiplashAudioBaseState

func _ready() -> void:
	MUSIC_NUM = MUSIC.VOTING
	_original_volume = volume_db
	volume_db = -80
