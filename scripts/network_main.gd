extends Node2D

# References
var chess_board = null
var game_controller = null
var chess_logic = null
var is_white_player = false
var is_my_turn = false

# UI references
@onready var turn_label = $CanvasLayer/TurnLabel
@onready var network_label = $CanvasLayer/NetworkLabel
@onready var back_button = $CanvasLayer/BackButton

func _ready():
	# Style the UI
	setup_ui()
	
	# Connect button
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Wait a frame to ensure all nodes are loaded
	await get_tree().process_frame
	
	# Check if we have valid network data
	if !get_node_or_null("/root/NetworkManager") or NetworkManager.game_state < NetworkManager.GameState.GAME_READY:
		print("ERROR: NetworkManager not found or game not ready!")
		network_label.text = "Network Error! Returning to menu..."
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
		return
	
	# Get our color from NetworkManager
	is_white_player = NetworkManager.my_info.is_white
	is_my_turn = is_white_player  # White goes first
	
	# Connect to NetworkManager signals
	if !NetworkManager.is_connected("move_received", _on_network_move_received):
		NetworkManager.connect("move_received", _on_network_move_received)
	if !NetworkManager.is_connected("checkmate_received", _on_network_checkmate_received):
		NetworkManager.connect("checkmate_received", _on_network_checkmate_received)
	if !NetworkManager.is_connected("player_disconnected", _on_player_disconnected):
		NetworkManager.connect("player_disconnected", _on_player_disconnected)
	
	# Get references to chess components
	chess_board = $ChessBoard
	if chess_board:
		game_controller = chess_board.get_node_or_null("GameController")
		chess_logic = chess_board.get_node_or_null("ChessLogic")
	
	if !chess_board or !game_controller or !chess_logic:
		push_error("ERROR: Required chess components not found!")
		return
	
	# Connect to chess signals
	if chess_logic.has_signal("move_made"):
		if !chess_logic.is_connected("move_made", _on_chess_move_made):
			chess_logic.connect("move_made", _on_chess_move_made)
	
	if game_controller.has_signal("game_state_changed"):
		if !game_controller.is_connected("game_state_changed", _on_game_state_changed):
			game_controller.connect("game_state_changed", _on_game_state_changed)
	
	if game_controller.has_signal("turn_changed"):
		if !game_controller.is_connected("turn_changed", _on_turn_changed):
			game_controller.connect("turn_changed", _on_turn_changed)
	
	# Setup the game with network armies
	setup_network_game()
	
	# Update UI
	update_ui()
	
	# Log our status
	print("Network game initialized. Playing as: " + ("WHITE" if is_white_player else "BLACK"))

# Setup the UI elements
func setup_ui():
	back_button.text = "Leave Game"
	
	turn_label.add_theme_font_size_override("font_size", 24)
	turn_label.add_theme_color_override("font_color", Color(1, 1, 1))
	turn_label.position = Vector2(10, 10)
	
	network_label.add_theme_font_size_override("font_size", 16)
	network_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	network_label.position = Vector2(10, 40)  # Below turn label

# Setup armies for networked game
func setup_network_game():
	# Log before doing anything
	print("Setting up network game. I am: " + ("WHITE" if is_white_player else "BLACK"))
	
	# Organize army data for both sides
	var army_data = {
		"white": {},
		"black": {}
	}
	
	# Get opponent data
	var opponent_id = NetworkManager.opponent_id
	var opponent_army = null
	if opponent_id != 0 and NetworkManager.player_info.has(opponent_id):
		opponent_army = NetworkManager.player_info[opponent_id].army_data
	else:
		push_error("ERROR: Opponent army data not found!")
		return
	
	# My army data
	var my_army = NetworkManager.my_info.army_data
	
	print("Army assignment: I am " + ("WHITE" if is_white_player else "BLACK"))
	
	# Assign armies based on color
	if is_white_player:
		# I'm white, opponent is black
		army_data.white = my_army
		army_data.black = opponent_army
		print("Setting WHITE army as my army")
		print("Setting BLACK army as opponent's army")
	else:
		# I'm black, opponent is white
		army_data.white = opponent_army
		army_data.black = my_army
		print("Setting WHITE army as opponent's army")
		print("Setting BLACK army as my army")
	
	# Load armies into game controller
	if game_controller.has_method("load_custom_army"):
		print("Loading armies into game controller...")
		# Prevent auto-start if it has that property
		if "auto_start" in game_controller:
			game_controller.auto_start = false
		game_controller.load_custom_army(army_data)
	else:
		push_error("ERROR: GameController doesn't have load_custom_army method")

# Update UI based on game state
func update_ui():
	# Update the network label
	network_label.text = "Playing as " + ("WHITE" if is_white_player else "BLACK")
	
	# Update turn information
	if !game_controller:
		return
		
	var is_white_turn = game_controller.get_is_white_turn()
	if is_white_turn == null:
		is_white_turn = true
	
	# Check if it's my turn
	is_my_turn = (is_white_turn == is_white_player)
	
	var turn_text = "White's Turn" if is_white_turn else "Black's Turn"
	if is_my_turn:
		turn_text += " (YOUR TURN)"
	else:
		turn_text += " (OPPONENT'S TURN)"
	
	# Update game state
	var state = game_controller.get_current_state()
	if state != null:
		# Use the correct state values
		match state:
			2:  # GameState.CHECK
				turn_text += " (Check!)"
			3:  # GameState.CHECKMATE
				var result = game_controller.get_game_result()
				if result and result != "":
					turn_text = result
				else:
					turn_text += " (Checkmate!)"
				
				# Send checkmate to opponent if it's my turn
				if is_my_turn:
					NetworkManager.send_checkmate()
			4:  # GameState.STALEMATE
				turn_text = "Draw by Stalemate"
			5:  # GameState.DRAW
				turn_text = "Draw"
	
	# Display turn text
	turn_label.text = turn_text

# Handler for when local player makes a move
func _on_chess_move_made(unit, from_pos, to_pos, is_capture, captured_unit):
	if is_my_turn:
		print("Sending move to opponent: ", from_pos, " -> ", to_pos)
		NetworkManager.send_move(from_pos, to_pos)

# Handler for when we receive a move from the opponent
func _on_network_move_received(from_pos, to_pos):
	print("Received move from opponent: ", from_pos, " -> ", to_pos)
	
	# Execute the move in our chess logic
	if chess_logic:
		var unit = chess_logic.get_unit_at(from_pos.x, from_pos.y)
		if unit != null:
			chess_logic.make_move(unit, from_pos, to_pos)
		else:
			push_error("ERROR: No unit found at position " + str(from_pos))
	else:
		push_error("ERROR: ChessLogic not found")

# Handler for when opponent sends checkmate
func _on_network_checkmate_received():
	print("Opponent declared checkmate!")
	# Game state will be updated by the move that caused checkmate

# Handler for game state changes
func _on_game_state_changed(state):
	print("Game state changed to: ", state)
	update_ui()

# Handler for turn changes
func _on_turn_changed(is_white_turn):
	print("Turn changed to: ", "White" if is_white_turn else "Black")
	update_ui()

# Handler for player disconnection
func _on_player_disconnected(id):
	print("Opponent disconnected!")
	network_label.text = "Opponent disconnected!"
	network_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))  # Red warning color

# Button handler to leave the game
func _on_back_button_pressed():
	# Disconnect from NetworkManager
	NetworkManager.disconnect_from_game()
	
	# Return to lobby
	get_tree().change_scene_to_file("res://scenes/ui/lobby_menu.tscn")
