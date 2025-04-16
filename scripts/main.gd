extends Node2D

# References
var chess_board = null
var game_controller = null
var turn_label = null
var custom_army_data = null

func _ready():
	# Wait one frame to make sure all nodes are loaded
	await get_tree().process_frame
	
	# Load custom army data if available
	load_custom_army_data()
	
	# Find references more reliably
	chess_board = find_node_by_name("ChessBoard")
	if not chess_board:
		push_error("ERROR: ChessBoard not found in main.gd")
		return
	
	# Find the game controller
	game_controller = find_node_by_name("GameController")
	if not game_controller:
		push_error("ERROR: GameController not found in main.gd")
		return
	
	# Set up the camera to view the board properly
	if chess_board and has_node("Camera2D"):
		var board_sprite = find_node_by_name("BoardSprite")
		if board_sprite:
			$Camera2D.position = board_sprite.global_position

	# Create UI elements if they don't exist
	setup_ui()

	# Wait for GameController to be fully initialized
	if game_controller.has_signal("initialized"):
		if not game_controller.is_connected("initialized", _on_game_controller_initialized):
			game_controller.connect("initialized", _on_game_controller_initialized)
	else:
		print("WARNING: GameController doesn't have initialized signal. Proceeding anyway.")
		call_deferred("_on_game_controller_initialized")

	# Disconnect any existing connections to avoid duplicates
	if game_controller:
		if game_controller.is_connected("game_state_changed", _on_game_state_changed):
			game_controller.game_state_changed.disconnect(_on_game_state_changed)
		if game_controller.is_connected("turn_changed", _on_turn_changed):
			game_controller.turn_changed.disconnect(_on_turn_changed)
		
		# Connect to game controller signals
		game_controller.game_state_changed.connect(_on_game_state_changed)
		game_controller.turn_changed.connect(_on_turn_changed)

	# Update the UI initially
	update_ui()

# Load custom army data from temp file
func load_custom_army_data():
	var file = FileAccess.open("user://temp_game_data.json", FileAccess.READ)
	if file:
		var text = file.get_as_text()
		file.close()
		
		print("Loading game data: " + text)
		
		var json = JSON.new()
		var error = json.parse(text)
		if error == OK:
			var data = json.get_data()
			if data and data.has("army_data") and data.army_data != null:
				custom_army_data = data.army_data
				print("Custom army data loaded successfully")
			else:
				print("Using standard army (no custom data found in temp file)")
		else:
			print("JSON parse error: " + json.get_error_message())

# Handle GameController initialization
func _on_game_controller_initialized():
	print("Main: GameController initialized, setting up game...")
	
	# Setup the game with custom army if available
	if custom_army_data != null:
		print("Main: Starting game with custom army configuration!")
		if game_controller.has_method("load_custom_army"):
			# Prevent game controller from auto-starting if it has that property
			if "auto_start" in game_controller:
				game_controller.auto_start = false
			game_controller.load_custom_army(custom_army_data)
		else:
			print("ERROR: GameController doesn't have load_custom_army method")
	else:
		print("Main: Starting game with standard chess configuration")
		# Allow auto-start if it has that property
		if "auto_start" in game_controller:
			game_controller.auto_start = true
		if game_controller.has_method("start_game"):
			game_controller.start_game()
		else:
			print("ERROR: GameController doesn't have start_game method")

# Function to find a node by name recursively
func find_node_by_name(node_name):
	return find_node_by_name_recursive(self, node_name)

func find_node_by_name_recursive(node, node_name):
	if node.name == node_name:
		return node
		
	for child in node.get_children():
		var found = find_node_by_name_recursive(child, node_name)
		if found:
			return found
			
	return null

# Set up UI elements
func setup_ui():
	# Check if we need to create a Canvas Layer
	var canvas_layer = get_node_or_null("CanvasLayer")
	if not canvas_layer:
		canvas_layer = CanvasLayer.new()
		canvas_layer.name = "CanvasLayer"
		add_child(canvas_layer)

	# Create turn label if it doesn't exist
	turn_label = canvas_layer.get_node_or_null("TurnLabel")
	if not turn_label:
		turn_label = Label.new()
		turn_label.name = "TurnLabel"
		turn_label.position = Vector2(10, 10)
		turn_label.add_theme_color_override("font_color", Color(1, 1, 1))
		turn_label.add_theme_font_size_override("font_size", 24)
		canvas_layer.add_child(turn_label)

# Update the UI based on game state
func update_ui():
	if not game_controller:
		print("ERROR: game_controller is null in update_ui()")
		return
		
	if not turn_label:
		print("ERROR: turn_label is null in update_ui()")
		return

	# Use the getter method instead of direct access
	var is_white_turn = game_controller.get_is_white_turn()
	if is_white_turn == null:
		# Default value if we can't determine whose turn it is
		is_white_turn = true
		print("WARNING: Could not determine whose turn it is, defaulting to White")
		
	var turn_text = "White's Turn" if is_white_turn else "Black's Turn"
	
	# Update game state
	var state = game_controller.get_current_state()
	if state != null:
		# Use the correct state values - CHECK is 2, not 1
		match state:
			2:  # GameState.CHECK
				turn_text += " (Check!)"
			3:  # GameState.CHECKMATE
				var result = game_controller.get_game_result()
				if result and result != "":
					turn_text = result
				else:
					turn_text += " (Checkmate!)"
			4:  # GameState.STALEMATE
				turn_text = "Draw by Stalemate"
			5:  # GameState.DRAW
				turn_text = "Draw"
	
	# Display the turn text
	turn_label.text = turn_text
	# Output to console only when text actually changes
	print("UI Updated: " + turn_text)

# Called when game state changes
func _on_game_state_changed(state):
	print("Game state changed to: ", state)
	update_ui()

# Called when turn changes
func _on_turn_changed(is_white_turn):
	print("Turn changed to: ", "White" if is_white_turn else "Black")
	update_ui()
