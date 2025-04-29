extends QuiplashBaseState

@export var _host_manager: QuiplashHostManager
@export var _scores_label: Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	STATE_NUM = States.SCORING

func received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer):
	if packet_id == QuiplashRoomManager.PacketID.PLAYER_SEND_RESPONSE:
		_host_manager._player_data

#overwrite base update
func update(_delta: float):
	pass

#overwrite base enter
func enter():
	var players = _host_manager._player_data.values()
	players.sort_custom(func(a, b): return a["score"] > b["score"])
	var text = ""
	for i in range(len(players)):
		var player = players[i]
		text += "%s) %s: %s" % [i + 1, player["username"], player["score"]]
		if i < len(players) - 1:
			text += "\n"
	_scores_label.text = text
