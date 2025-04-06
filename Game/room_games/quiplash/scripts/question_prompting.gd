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
	
	# Shuffle player ids to ensure first 2-players don't always get paired together
	# Questions are already shuffled
	var shuffled_players = _quiplash_host_manager._player_data.keys()
	# As a player, how many questions are you expected to 
	# repond to in this round?
	# NOTE: Each question is given to exactly 2 players
	var questions_per_player = 2
	
	# Map player_id -> Array of questions
	# Ex. 1: [{ id: 1, text: "What's 10 + 11?"}]
	var player_questions: Dictionary = {}
	for player_id in _quiplash_host_manager._player_data:
		player_questions[player_id] = []
	for i in range(questions_per_player):
		shuffled_players.shuffle()
		for player_index in range(0, len(shuffled_players), 2):
			var new_question = _quiplash_host_manager.get_new_question()
			if player_index + 1 < len(shuffled_players):
				# Pair up this player and the next player
				player_questions[shuffled_players[player_index]].append({
					"id": new_question["index"], 
					"text": new_question["question"]
				})
				player_questions[shuffled_players[player_index + 1]].append({
					"id": new_question["index"], 
					"text": new_question["question"]
				})
			else:
				# We are the last-odd player out, pick 
				# the first player
				assert(player_index != 0, "Expected >= 2 players to give out question to 2 unique players!")
				player_questions[shuffled_players[player_index]].append({
					"id": new_question["index"], 
					"text": new_question["question"]
				})
				player_questions[shuffled_players[0]].append({
					"id": new_question["index"], 
					"text": new_question["question"]
				})
	for player_id in player_questions:
		_quiplash_room_manager.host_send_questions_to_player(player_id, player_questions[player_id])
	_update_players_label()

func _update_players_label():
	var text = "Players Ready (%s/%s)\n" % [_responded_players, len(_quiplash_host_manager._player_data)]
	for player in _quiplash_host_manager._player_data.values():
		text += "\n* %s %s" % [player["username"], player["responded"] if "(DONE)" else ""]
	_players_label.text = text
