extends Node

signal unit_placed(unit_type, is_white, x, y)
signal unit_removed(x, y)

# Reference to the board and chess logic
var board_view = null
var chess_logic = null
var units_node = null  # Node to parent units under

# Sound effects
var capture_sound
var move_sound

func _ready():
	# Load sound effects
	capture_sound = load("res://assets/sounds/capture.mp3")
	move_sound = load("res://assets/sounds/move-self.mp3")
	
	# Test sounds initialized properly
	print("UnitPlacer: Sound effects loaded - Capture:", capture_sound != null, ", Move:", move_sound != null)

# Set references
func set_references(board_view_ref, chess_logic_ref, units_node_ref):
	board_view = board_view_ref
	chess_logic = chess_logic_ref
	units_node = units_node_ref
	
	# Connect to chess_logic signals to play sounds
	if chess_logic and chess_logic.has_signal("move_made"):
		chess_logic.move_made.connect(_on_move_made)

# Handle unit movement for sound effects
func _on_move_made(unit, from_pos, to_pos, is_capture, captured_unit):
	# Play the appropriate sound effect
	play_move_sound(is_capture)

# Create and place a unit
func create_unit(unit_type, is_white, x, y):
	# Check if position is valid
	if x < 0 or x > 7 or y < 0 or y > 7:
		print("ERROR: Invalid position for unit placement: ", x, ", ", y)
		return null
	
	# Check if there's already a unit at this position
	if chess_logic.get_unit_at(x, y) != null:
		print("Removing existing unit at ", x, ", ", y)
		remove_unit(x, y)
	
	# Load the unit scene
	var unit_scene = load("res://scenes/units/" + unit_type.to_lower() + ".tscn")
	if not unit_scene:
		print("ERROR: Could not load unit scene: ", unit_type)
		return null
	
	# Instance the unit
	var unit = unit_scene.instantiate()
	
	# Add to the scene tree
	units_node.add_child(unit)
	
	# Get the position from the board
	var screen_pos = board_view.board_to_screen(x, y)
	
	# Initialize the unit
	unit.initialize(is_white, Vector2(x, y), chess_logic.board, unit_type)
	
	# Set the position
	unit.position = screen_pos
	
	# Add the unit to the game board
	chess_logic.place_unit(unit, x, y)
	
	# Emit signal
	unit_placed.emit(unit_type, is_white, x, y)
	
	return unit

# Remove a unit at a position
func remove_unit(x, y):
	var unit = chess_logic.get_unit_at(x, y)
	if unit != null:
		# Remove from board logic
		chess_logic.remove_unit(x, y)
		
		# Remove from scene tree
		unit.queue_free()
		
		# Emit signal
		unit_removed.emit(x, y)
		
		return true
	
	return false

# Move a unit on the board (visually and logically)
func move_unit(unit, from_pos, to_pos):
	if unit == null:
		return false
	
	# Make the move in the chess logic
	var is_capture = chess_logic.make_move(unit, from_pos, to_pos)
	
	# Update visual position
	unit.position = board_view.board_to_screen(to_pos.x, to_pos.y)
	
	# Note: Sound is now handled by the _on_move_made signal connection
	
	return true

# Play sound based on move type
func play_move_sound(is_capture):
	print("Playing sound for move. Is capture:", is_capture)
	
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

# Setup the initial chess position
func setup_standard_position():
	# Back row units (black)
	create_unit("Rook", false, 0, 0)
	create_unit("Knight", false, 1, 0)
	create_unit("Bishop", false, 2, 0)
	create_unit("Queen", false, 3, 0)
	create_unit("King", false, 4, 0)
	create_unit("Bishop", false, 5, 0)
	create_unit("Knight", false, 6, 0)
	create_unit("Rook", false, 7, 0)
	
	# Black pawns
	for i in range(8):
		create_unit("Pawn", false, i, 1)
	
	# White pawns
	for i in range(8):
		create_unit("Pawn", true, i, 6)
	
	# White back row
	create_unit("Rook", true, 0, 7)
	create_unit("Knight", true, 1, 7)
	create_unit("Bishop", true, 2, 7)
	create_unit("Queen", true, 3, 7)
	create_unit("King", true, 4, 7)
	create_unit("Bishop", true, 5, 7)
	create_unit("Knight", true, 6, 7)
	create_unit("Rook", true, 7, 7)

# Clear all units
func clear_board():
	for x in range(8):
		for y in range(8):
			remove_unit(x, y)

# Setup custom army from data
func setup_custom_army(army_data, is_white=true):
	# Calculate row offsets based on side
	var row_offset = 0
	if is_white:
		row_offset = 5  # Start at row 5 for white (rows 5,6,7)
	
	# Parse and place each unit
	for pos_str in army_data.keys():
		var unit_type = army_data[pos_str]
		
		# Parse position string
		var pos_x = 0
		var pos_y = 0
		
		if pos_str.contains(","):
			var clean_str = pos_str.replace("(", "").replace(")", "").replace(" ", "")
			var parts = clean_str.split(",")
			if parts.size() >= 2:
				pos_x = int(parts[0])
				pos_y = int(parts[1])
				
				# Adjust row for proper side if needed
				if is_white and pos_y < 5:
					pos_y += row_offset
		
		# Create the unit
		create_unit(unit_type, is_white, pos_x, pos_y)
