extends Node2D
class_name BaseUnit
# Unit properties
var is_white = true
var board_position = Vector2(0, 0)
var has_moved = false
var unit_value = 0  # Points value (for Chess 100)
var unit_type = "None"
var is_selected = false
# Board reference
var board = null
# Reference to the sprite
@onready var sprite = $Sprite2D
# Called when the node enters the scene tree
func _ready():
	pass
# Initialize the unit
func initialize(white, pos, board_ref=null, type=null):
	is_white = white
	board_position = pos
	
	# Store board reference if provided
	if board_ref:
		board = board_ref
	
	# Set unit type if provided by parameter (overrides the default)
	if type:
		unit_type = type
	
	# Set the sprite texture based on color (only if unit_type is not "None")
	if unit_type != "None":
		update_sprite()
# Update sprite texture based on unit color
func update_sprite():
	var color_folder = "whiteunits" if is_white else "blackunits"
	# Note the capitalization in the filename to match your assets
	var sprite_path = "res://assets/sprites/%s/%s.png" % [color_folder, unit_type]
	sprite.texture = load(sprite_path)
# Set whether this unit is selected
func set_selected(selected):
	is_selected = selected
	if is_selected:
		# Add a highlight effect when selected
		modulate = Color(1.5, 1.5, 0.5)  # Yellow-ish highlight
	else:
		# Return to normal when deselected
		modulate = Color(1, 1, 1)  # Normal color
# Move to a new position on the board
func move_to(new_pos):
	board_position = new_pos
	has_moved = true

# Get the raw movement pattern of this unit WITHOUT safety checks
# This is used for calculating attacks and check detection
func get_movement_pattern():
	# Base implementation returns an empty array
	# Child classes should override this with their specific movement patterns
	return []

# Get all valid moves for this unit (including king safety)
func get_valid_moves():
	# Get the raw moves first
	var moves = get_movement_pattern()
	
	# Find the game manager to filter out moves that would put the king in check
	var game_manager = find_game_manager()
	if game_manager:
		# Filter out moves that would leave the king in check
		var safe_moves = []
		for move in moves:
			if not would_leave_king_in_check(move):
				safe_moves.append(move)
		return safe_moves
	
	# If no game manager, just return the raw moves
	return moves

# Check if this unit can attack a specific square (used for check detection)
# This method should NOT involve recursive calls to check detection
func can_attack_square(square_pos):
	# Get the basic movement pattern
	var moves = get_movement_pattern()
	
	# Check if the target square is in the movement pattern
	for square in moves:
		if square == square_pos:
			return true
	
	return false

# Check if a move would leave the king in check
func would_leave_king_in_check(target_pos):
	# Save original state
	var original_pos = board_position
	var target_unit = board[int(target_pos.x)][int(target_pos.y)]
	
	# Temporarily make the move
	board[int(original_pos.x)][int(original_pos.y)] = null
	board[int(target_pos.x)][int(target_pos.y)] = self
	
	# Check if king would be in check
	var in_check = false
	var game_manager = find_game_manager()
	if game_manager:
		in_check = game_manager.is_king_in_check(is_white)
	
	# Restore original state
	board[int(original_pos.x)][int(original_pos.y)] = self
	board[int(target_pos.x)][int(target_pos.y)] = target_unit
	
	return in_check

# Find the GameManager node
func find_game_manager():
	var root = get_tree().get_root()
	var main = root.get_child(root.get_child_count() - 1)
	if main and main.has_node("GameManager"):
		return main.get_node("GameManager")
	return null

# Check if a position is on the board
func is_on_board(pos):
	return pos.x >= 0 and pos.x < 8 and pos.y >= 0 and pos.y < 8
# Check if a position contains a friendly unit
func is_friendly_unit(pos):
	# Make sure we have a valid board reference
	ensure_board_reference()
	
	# Safety check
	if not board or not is_on_board(pos):
		return false
	
	var unit = board[int(pos.x)][int(pos.y)]
	return unit != null and unit.is_white == is_white
# Check if a position contains an enemy unit
func is_enemy_unit(pos):
	# Make sure we have a valid board reference
	ensure_board_reference()
	
	# Safety check
	if not board or not is_on_board(pos):
		return false
	
	var unit = board[int(pos.x)][int(pos.y)]
	return unit != null and unit.is_white != is_white
# Check if a position is empty
func is_empty(pos):
	# Make sure we have a valid board reference
	ensure_board_reference()
	
	# Safety check
	if not board or not is_on_board(pos):
		return false
	
	return board[int(pos.x)][int(pos.y)] == null
# More reliable way to get the board reference
func ensure_board_reference():
	if board != null:
		return
	# Try to find the board by traversing up the scene tree
	var current = self
	while current != null:
		if current.get_parent() and current.get_parent().has_method("get_board"):
			board = current.get_parent().get_board()
			return
		
		# Check for Units node (a common parent)
		if current.get_parent() and current.get_parent().name == "Units":
			if current.get_parent().get_parent() and current.get_parent().get_parent().has_method("get_board"):
				board = current.get_parent().get_parent().get_board()
				return
		
		current = current.get_parent()
