extends QuiplashBaseState
@export var _waiting_panel: PanelContainer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	STATE_NUM = States.SCORING
	_waiting_panel.visible = true
