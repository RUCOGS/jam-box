extends QuiplashBaseState

@export var _quiplash_host_manager: QuiplashHostManager
@export var _quiplash_room_manager: QuiplashRoomManager

@export var _players_label: Label

var _responded_players: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	STATE_NUM = States.QUESTIONS

func received_packet(sender_id: int, packet_id: int, buffer: ByteBuffer):
	pass

#overwrite base update
func update(_delta: float):
	pass

#overwrite base enter
func enter():
	# Reset
	_responded_players = 0
	
	# Distribute questions -- first question goes to first two players, second goes to next to...
	# ... and so on
	
	# Shuffle players to ensure first 2-players don't always get paired together
	# Questions are already shuffled
	var shuffled_players = _quiplash_host_manager._player_data.keys()
	# As a player, how many questions are you expected to 
	# repond to in this round?
	# NOTE: Each question is given to exactly 2 players
	var questions_per_player = 2
	
	for i in range(questions_per_player):
		shuffled_players.shuffle()
		for player_index in range(len(shuffled_players)):
			var new_question = _quiplash_host_manager.get_new_question()
			if player_index + 1 < len(shuffled_players):
				# Pair up this player and the next player
				_quiplash_room_manager.send_question_to_player(shuffled_players[player_index], new_question["index"], new_question["question"])
				_quiplash_room_manager.send_question_to_player(shuffled_players[player_index + 1], new_question["index"], new_question["question"])
			else:
				# We are the last-odd player out, pick 
				# the first player
				_quiplash_room_manager.send_question_to_player(shuffled_players[player_index], new_question["index"], new_question["question"])
				_quiplash_room_manager.send_question_to_player(shuffled_players[0], new_question["index"], new_question["question"])
	_update_players_label()

func _update_players_label():
	var text = "Players Ready (%s/%s)\n" % [_responded_players, len(_quiplash_host_manager._player_data)]
	for player in _quiplash_host_manager._player_data.values():
		text += "\n* %s %s" % [player["username"], player["responded"] if "(DONE)" else ""]
	_players_label.text = text
