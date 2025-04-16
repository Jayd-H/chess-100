extends Node

# Game state signals
signal game_state_changed(state)
signal turn_changed(is_white_turn)

# Game states
enum GameState {
	SETUP,
	PLAYING,
	CHECK,
	CHECKMATE,
	STALEMATE,
	DRAW
}

# Current game state
var current_state = GameState.SETUP
var selected_square = null
var game_result = ""

# References to components
var board_view = null
var chess_logic = null
var unit_placer = null

# Check highlight tracking
var check_highlight_pos = null

# Sound effects
var capture_sound
var move_sound

# Flag to avoid initial check detection
var game_initialized = false

# Called when the node enters the scene tree
func _ready():
	# Wait one frame to make sure all nodes are loaded
	await get_tree().process_frame
	
	print("GameController: Ready function called")
	
	# Find references more reliably
	board_view = get_node_or_null("../BoardView")
	if not board_view:
		board_view = find_node_by_name("BoardView")
	
	chess_logic = get_node_or_null("../ChessLogic")
	if not chess_logic:
		chess_logic = find_node_by_name("ChessLogic")
	
	unit_placer = get_node_or_null("../UnitPlacer")
	if not unit_placer:
		unit_placer = find_node_by_name("UnitPlacer")
	
	var units_node = null
	if board_view:
		units_node = board_view.get_node_or_null("Units")
	
	# Log errors if components not found
	if not board_view:
		push_error("ERROR: BoardView not found in GameController")
	else:
		print("GameController: Found BoardView")
		
	if not chess_logic:
		push_error("ERROR: ChessLogic not found in GameController")
	else:
		print("GameController: Found ChessLogic")
		
	if not unit_placer:
		push_error("ERROR: UnitPlacer not found in GameController")
	else:
		print("GameController: Found UnitPlacer")
	
	# Load sound effects
	capture_sound = load("res://assets/sounds/capture.mp3")
	move_sound = load("res://assets/sounds/move-self.mp3")
	
	# Connect to board_view signals
	if board_view:
		if board_view.has_signal("square_clicked"):
			if not board_view.is_connected("square_clicked", _on_square_clicked):
				board_view.square_clicked.connect(_on_square_clicked)
		if board_view.has_signal("square_hovered"):
			if not board_view.is_connected("square_hovered", _on_square_hovered):
				board_view.square_hovered.connect(_on_square_hovered)
	
	# Connect to chess_logic signals
	if chess_logic:
		if chess_logic.has_signal("move_made"):
			if not chess_logic.is_connected("move_made", _on_move_made):
				chess_logic.move_made.connect(_on_move_made)
		if chess_logic.has_signal("turn_changed"):
			if not chess_logic.is_connected("turn_changed", _on_turn_changed):
				chess_logic.turn_changed.connect(_on_turn_changed)
		if chess_logic.has_signal("check_occurred"):
			if not chess_logic.is_connected("check_occurred", _on_check_occurred):
				chess_logic.check_occurred.connect(_on_check_occurred)
		if chess_logic.has_signal("checkmate_occurred"):
			if not chess_logic.is_connected("checkmate_occurred", _on_checkmate_occurred):
				chess_logic.checkmate_occurred.connect(_on_checkmate_occurred)
		if chess_logic.has_signal("stalemate_occurred"):
			if not chess_logic.is_connected("stalemate_occurred", _on_stalemate_occurred):
				chess_logic.stalemate_occurred.connect(_on_stalemate_occurred)
	
	# Connect to unit_placer signals
	if unit_placer:
		if unit_placer.has_signal("unit_placed"):
			if not unit_placer.is_connected("unit_placed", _on_unit_placed):
				unit_placer.unit_placed.connect(_on_unit_placed)
		if unit_placer.has_signal("unit_removed"):
			if not unit_placer.is_connected("unit_removed", _on_unit_removed):
				unit_placer.unit_removed.connect(_on_unit_removed)
	
	# Set up references between components
	if unit_placer and board_view and chess_logic and units_node:
		unit_placer.set_references(board_view, chess_logic, units_node)
	
	# Set initial state
	change_game_state(GameState.SETUP)
	
	# Initialize game
	start_game()

# Function to find node by name recursively
func find_node_by_name(node_name):
	return find_node_by_name_recursive(get_tree().root, node_name)

func find_node_by_name_recursive(node, node_name):
	if node.name == node_name:
		return node
		
	for child in node.get_children():
		var found = find_node_by_name_recursive(child, node_name)
		if found:
			return found
			
	return null

# Handle square clicks
func _on_square_clicked(x, y):
	if current_state == GameState.PLAYING or current_state == GameState.CHECK:
		# Let chess logic handle the click
		if chess_logic:
			var result = chess_logic.handle_square_click(x, y)
			
			if result:
				# Clear previously selected square
				if selected_square != null and board_view:
					board_view.highlight_square(selected_square.x, selected_square.y, false)
				
				# Update selected unit visualization
				if chess_logic.selected_unit != null:
					# Highlight the selected square
					if board_view:
						board_view.highlight_selected_square(x, y)
					selected_square = Vector2(x, y)
					
					# Show valid moves
					show_valid_moves()
				else:
					# Clear valid move highlights
					if board_view:
						board_view.clear_all_highlights()
					selected_square = null
					
					# Reapply check highlight if needed
					if current_state == GameState.CHECK:
						update_check_highlight()

# Update the check highlight if the king is in check
func update_check_highlight():
	if current_state == GameState.CHECK and chess_logic and board_view:
		var is_white_turn = chess_logic.is_white_turn
		var king_pos = chess_logic.find_king(is_white_turn)
		if king_pos != null:
			board_view.highlight_check_square(king_pos.x, king_pos.y)
			check_highlight_pos = king_pos

# Handle square hover
func _on_square_hovered(x, y):
	# Can add hover effects or info display here
	pass

# Display valid moves for selected unit
func show_valid_moves():
	# Clear previous highlights but keep selected square
	if board_view:
		board_view.clear_all_highlights()
	
	if selected_square != null and board_view:
		board_view.highlight_selected_square(selected_square.x, selected_square.y)
	
	# Reapply check highlight if needed
	if current_state == GameState.CHECK:
		update_check_highlight()
	
	if chess_logic and chess_logic.selected_unit != null:
		var valid_moves = chess_logic.get_valid_moves_for_selected()
		
		# Highlight valid move squares
		for move in valid_moves:
			var x = int(move.x)
			var y = int(move.y)
			
			# Check if this is a capture move
			if chess_logic.get_unit_at(x, y) != null:
				if board_view:
					board_view.highlight_capture_square(x, y)
			else:
				if board_view:
					board_view.highlight_square(x, y, true)

# Handle when a move is made
func _on_move_made(unit, from_pos, to_pos, is_capture, captured_unit):
	# Update unit visual position
	if board_view:
		unit.position = board_view.board_to_screen(to_pos.x, to_pos.y)
	
	# Clear highlights
	if board_view:
		board_view.clear_all_highlights()
	selected_square = null
	
	# Clear check highlight if any
	if check_highlight_pos != null and board_view:
		board_view.highlight_square(check_highlight_pos.x, check_highlight_pos.y, false)
		check_highlight_pos = null
	
	# Reset to PLAYING state - the check detection will set it back if needed
	change_game_state(GameState.PLAYING)
	
	# Play sound effect
	play_move_sound(is_capture)
	
	# Free any captured unit
	if captured_unit != null:
		captured_unit.queue_free()

# Play sound based on move type
func play_move_sound(is_capture):
	# Create an AudioStreamPlayer for the sound
	var audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	if is_capture:
		# Play capture sound
		audio_player.stream = capture_sound
	else:
		# Play regular move sound
		audio_player.stream = move_sound
	
	# Play the sound
	audio_player.play()
	
	# Set up to automatically remove the audio player when done
	audio_player.finished.connect(func(): audio_player.queue_free())

# Handle turn changes
func _on_turn_changed(is_white_turn):
	# Update UI or other elements that need to know about turn changes
	turn_changed.emit(is_white_turn)

# Handle check state
func _on_check_occurred(is_white_king):
	# Only process check state if game has properly initialized
	if not game_initialized:
		return
		
	# Change game state
	change_game_state(GameState.CHECK)
	
	# Highlight the king in check
	if chess_logic:
		var king_pos = chess_logic.find_king(is_white_king)
		if king_pos != null and board_view:
			board_view.highlight_check_square(king_pos.x, king_pos.y)
			check_highlight_pos = king_pos
			print("King in check! Highlighting king at", king_pos)

# Handle checkmate
func _on_checkmate_occurred(is_white_king):
	# Change game state
	change_game_state(GameState.CHECKMATE)
	
	# Set game result
	game_result = "Black wins!" if is_white_king else "White wins!"
	
	# Highlight the king in checkmate
	if chess_logic:
		var king_pos = chess_logic.find_king(is_white_king)
		if king_pos != null and board_view:
			board_view.highlight_check_square(king_pos.x, king_pos.y)

# Handle stalemate
func _on_stalemate_occurred():
	# Change game state
	change_game_state(GameState.STALEMATE)
	
	# Set game result
	game_result = "Draw by stalemate"

# Handle unit placement
func _on_unit_placed(unit_type, is_white, x, y):
	# Additional logic if needed after a unit is placed
	pass

# Handle unit removal
func _on_unit_removed(x, y):
	# Additional logic if needed after a unit is removed
	pass

# Start a new game
func start_game():
	print("GameController: Starting new game")
	# Explicitly set to false during setup
	game_initialized = false
	
	# Reset chess logic
	if chess_logic:
		chess_logic.reset_game()
	
	# Clear the board
	if unit_placer:
		unit_placer.clear_board()
	
	# Setup standard position
	if unit_placer:
		unit_placer.setup_standard_position()
	
	# Set state to playing
	change_game_state(GameState.PLAYING)
	
	# Delay setting game_initialized to avoid initial check detection
	await get_tree().process_frame
	await get_tree().process_frame
	game_initialized = true
	print("GameController: Game initialization complete")

# Load a custom army
func load_custom_army(army_data):
	print("GameController: Loading custom army")
	# Reset chess logic
	if chess_logic:
		chess_logic.reset_game()
	
	# Clear the board
	if unit_placer:
		unit_placer.clear_board()
	
	# Setup custom army
	if unit_placer:
		unit_placer.setup_custom_army(army_data)
	
	# Set state to playing
	change_game_state(GameState.PLAYING)
	
	# Delay setting game_initialized to avoid initial check detection
	await get_tree().process_frame
	await get_tree().process_frame
	game_initialized = true

# Change game state
func change_game_state(new_state):
	if current_state != new_state:
		print("GameController: Changing state from", current_state, "to", new_state)
		current_state = new_state
		game_state_changed.emit(current_state)

# Getter methods for other scripts to use
func get_game_result():
	return game_result

func get_current_state():
	return current_state

func get_is_white_turn():
	if chess_logic:
		return chess_logic.is_white_turn
	return true
