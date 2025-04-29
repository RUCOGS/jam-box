extends Control

var _time_remaining: float = 0
var _timer_running: bool = false
@export var _parent_manager: Control
@export var _timer_text: Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not _timer_running:
		return
	_time_remaining -= delta
	_timer_text.text = str(int(_time_remaining))
	if _time_remaining <= 0:
		_timer_running = false
		# do some things
		# this script is re-used, things will be handled in the _parent_manager ideally
		# also the _timer_up() function shouldn't do much in the player_manager as \
		# the host_manager should handle the timing of phase changes
		
		_parent_manager._timer_up()

func start_timer(duration: int) -> void:
	visible = true
	_time_remaining = duration
	_timer_running = true
