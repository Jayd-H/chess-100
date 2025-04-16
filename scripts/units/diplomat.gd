extends BaseUnit

signal peace_zone_changed
var peace_zone_squares = []

func _ready():
	unit_type = "Diplomat"
	unit_value = 10  # Increased from 6 to 10 points

# Get the basic movement pattern
func get_movement_pattern():
	ensure_board_reference()
	if not board:
		return []
		
	var moves = []
	var pos = board_position
	
	# Diplomat moves like a king - one square in any direction
	var directions = [
		Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(-1, 1),
		Vector2(-1, 0), Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1)
	]
	
	for dir in directions:
		var target = Vector2(pos.x + dir.x, pos.y + dir.y)
		
		if is_on_board(target) and is_empty(target):
			moves.append(target)
	
	return moves

# The Diplomat cannot capture
func can_attack_square(square_pos):
	return false

# Called after movement to update the peace zone
func move_to(new_pos):
	# Call parent implementation
	super.move_to(new_pos)
	
	# Update peace zone
	update_peace_zone()
	
	# Make sure the chess_logic knows we have diplomats
	var chess_logic = find_chess_logic()
	if chess_logic and "has_diplomats" in chess_logic:
		chess_logic.has_diplomats = true

# Find chess logic node
func find_chess_logic():
	var root = get_tree().get_root()
	return root.find_child("ChessLogic", true, false)

# Special function to update peace zone squares
func update_peace_zone():
	peace_zone_squares.clear()
	
	# Add only orthogonal adjacent squares to peace zone (not diagonals)
	var orthogonal_offsets = [
		Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)
	]
	
	for offset in orthogonal_offsets:
		var pos = Vector2(board_position.x + offset.x, board_position.y + offset.y)
		if is_on_board(pos):
			peace_zone_squares.append(pos)
	
	# Emit signal that peace zone has changed
	peace_zone_changed.emit()
	
	# Find board view to highlight squares
	highlight_peace_zone()

# Highlight peace zone squares
func highlight_peace_zone():
	var board_view = find_board_view()
	if not board_view:
		return
		
	for pos in peace_zone_squares:
		# Try different highlighting methods
		if board_view.has_method("highlight_special_square"):
			board_view.highlight_special_square(pos.x, pos.y, Color(0.2, 0.6, 0.9, 0.4))  # Light blue
		elif board_view.has_method("highlight_square"):
			# Fallback to standard highlight method if available
			board_view.highlight_square(pos.x, pos.y, true)

# Find the board view node
func find_board_view():
	var root = get_tree().get_root()
	return root.find_child("BoardView", true, false)

# Check if a position is in this diplomat's peace zone
func is_in_peace_zone(pos):
	# Check if the position is orthogonally adjacent
	var dx = abs(pos.x - board_position.x)
	var dy = abs(pos.y - board_position.y)
	
	# Position is in peace zone if it's orthogonally adjacent to diplomat
	return (dx == 1 and dy == 0) or (dx == 0 and dy == 1)

# STATIC METHODS FOR EXTERNAL CHECKS

# This method checks if a target position is protected by a diplomat
static func is_target_protected_by_diplomat(target_pos, board_ref):
	# First check if the target is a diplomat - diplomats can always be captured
	var target_piece = board_ref[int(target_pos.x)][int(target_pos.y)]
	if target_piece and target_piece.unit_type == "Diplomat":
		return false  # Diplomats are never protected
	
	# Check if the target position is in a diplomat's peace zone
	for x in range(8):
		for y in range(8):
			var piece = board_ref[x][y]
			if piece and piece.unit_type == "Diplomat":
				# Check if target is in peace zone (orthogonally adjacent only)
				var dx = abs(target_pos.x - x)
				var dy = abs(target_pos.y - y)
				var in_zone = (dx == 1 and dy == 0) or (dx == 0 and dy == 1)
				
				if in_zone:
					return true  # Target is protected
	
	return false  # Target is not protected
