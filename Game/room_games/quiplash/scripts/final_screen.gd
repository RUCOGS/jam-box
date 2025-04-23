extends Control

@export var _host_manager: QuiplashHostManager
@export var _scores_label: Label
@export var _winner_label: Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false

func update():
	var players = _host_manager._player_data.values()
	players.sort_custom(func(a, b): return a["score"] > b["score"])
	var text = ""
	for i in range(len(players)):
		var player = players[i]
		text += "%s) %s: %s" % [i + 1, player["username"], player["score"]]
		if i < len(players) - 1:
			text += "\n"
	_scores_label.text = text
	var win_text: String
	if (players[0]["score"] != players[1]["score"]):
		win_text = "%s wins the game!" % [players[0]["username"]]
	else:
		win_text = "There's a tie! "
		if len(players) == 2 or not players[1]["score"] == players[2]["score"]:
			win_text += "%s and %s are both winners!" % [players[0]["username"], players[1]["username"]]
			_winner_label.text = win_text
			return
		for i in range(len(players)):
			if not players[i]["score"] == players[0]["score"]:
				break
			if i + 1 == len(players) or not players[i]["score"] == players[i + 1]["score"]:
				win_text += "and %s" % [players[i]["username"]]
			else:
				win_text += "%s, " % [players[i]["username"]]
				
		win_text += " are all winners!"
	_winner_label.text = win_text
