extends BaseUnit

func _ready():
	unit_type = "Pawn"  # This must match your sprite filename
	unit_value = 4  # As per Chess 100 rules

# Get the basic movement pattern
func get_movement_pattern():
	# Make sure board reference is valid
	ensure_board_reference()
	if not board:
		print("ERROR: No board reference in Pawn")
		return []
	
	var moves = []
	var direction = -1 if is_white else 1
	var pos = board_position
	
	# Forward move (1 square)
	var forward = Vector2(pos.x, pos.y + direction)
	if is_on_board(forward) and is_empty(forward):
		moves.append(forward)
		
		# First move can be 2 squares forward
		if not has_moved:
			var double_forward = Vector2(pos.x, pos.y + 2 * direction)
			if is_on_board(double_forward) and is_empty(double_forward):
				moves.append(double_forward)
	
	# Capture diagonally
	var capture_left = Vector2(pos.x - 1, pos.y + direction)
	if is_on_board(capture_left) and is_enemy_unit(capture_left):
		moves.append(capture_left)
	
	var capture_right = Vector2(pos.x + 1, pos.y + direction)
	if is_on_board(capture_right) and is_enemy_unit(capture_right):
		moves.append(capture_right)
	
	return moves

# Get special moves like en passant
func get_special_moves(last_move):
	if not last_move:
		return []
		
	ensure_board_reference()
	if not board:
		return []
		
	var moves = []
	var direction = -1 if is_white else 1
	var pos = board_position
	
	# En passant check
	var last_unit = last_move.unit
	var from_pos = last_move.from
	var to_pos = last_move.to
	
	# Check if the last move was a pawn moving two squares
	if last_unit.unit_type == "Pawn" and abs(from_pos.y - to_pos.y) == 2:
		# Check if that pawn is now beside us (same rank)
		if to_pos.y == pos.y and abs(to_pos.x - pos.x) == 1:
			# Add en passant capture move
			var capture_pos = Vector2(to_pos.x, pos.y + direction)
			# Debug output
			print("En Passant capture available from ", pos, " to ", capture_pos)
			print("Target pawn is at ", to_pos)
			moves.append(capture_pos)
	
	return moves

# Handle special move like en passant
func handle_special_move(from_pos, to_pos, last_move, board_ref):
	if not last_move:
		return null
		
	# Check specifically for en passant move conditions
	if to_pos.x != from_pos.x and is_empty(Vector2(to_pos.x, to_pos.y)) and last_move:
		print("Potential en passant detected:")
		print("- Moving from ", from_pos, " to ", to_pos)
		print("- Last move was from ", last_move.from, " to ", last_move.to)
		
		# En passant capture - captured pawn is at the same rank as our pawn but at the column we're moving to
		var captured_pawn_pos = Vector2(to_pos.x, from_pos.y)
		
		print("Checking for captured pawn at ", captured_pawn_pos)
		
		# Verify if there's actually a pawn at this position
		if is_on_board(captured_pawn_pos):
			var captured_piece = board_ref[int(captured_pawn_pos.x)][int(captured_pawn_pos.y)]
			if captured_piece != null:
				print("Found piece at captured position: ", captured_piece.unit_type, " (", "white" if captured_piece.is_white else "black", ")")
			else:
				print("No piece found at captured position")
				
			# Check if this is a valid en passant capture
			if captured_piece and captured_piece.unit_type == "Pawn" and captured_piece.is_white != is_white:
				# Verify this was the pawn that just moved two squares
				if last_move and last_move.unit == captured_piece:
					print("Valid en passant! Removing captured pawn")
					
					# Remove the captured pawn from the board array
					board_ref[int(captured_pawn_pos.x)][int(captured_pawn_pos.y)] = null
					
					# Note: We don't free the piece here because the caller should handle that
					# after receiving it as a return value
					return captured_piece
				else:
					print("Not a valid en passant - not the pawn that just moved")
	
	# Check for promotion
	if (is_white and to_pos.y == 0) or (!is_white and to_pos.y == 7):
		# Flag for promotion - we'll handle this after the move is completed
		call_deferred("handle_promotion", to_pos)
		
	return null

# Handle promotion after move is completed
func handle_promotion(pos):
	# For now, automatically promote to Queen
	promote_to("Queen")

# Handle promotion
func promote_to(new_unit_type):
	print("Promoting pawn to ", new_unit_type)
	
	# Ensure board reference is valid
	ensure_board_reference()
	if not board:
		print("ERROR: Board reference missing during promotion")
		return
		
	# Find the Units node
	var units_node = get_parent()
	if not units_node:
		print("ERROR: Could not find parent node for promotion")
		return
		
	# Create the new unit
	var new_unit_scene = load("res://scenes/units/" + new_unit_type.to_lower() + ".tscn")
	if new_unit_scene:
		var new_unit = new_unit_scene.instantiate()
		
		# Add to scene first
		units_node.add_child(new_unit)
		
		# Initialize after adding to scene
		new_unit.initialize(is_white, board_position, board, new_unit_type)
		
		# Set position explicitly
		new_unit.position = position
		
		# Update the board array
		board[int(board_position.x)][int(board_position.y)] = new_unit
		
		print("Promotion successful!")
		
		# Remove this pawn
		queue_free()
	else:
		print("ERROR: Could not load " + new_unit_type + " scene")

# Override can_attack_square for pawns since their attack pattern differs from movement
func can_attack_square(square_pos):
	ensure_board_reference()
	if not board:
		return false
		
	var direction = -1 if is_white else 1
	var pos = board_position
	
	# Pawns attack diagonally
	var attack_left = Vector2(pos.x - 1, pos.y + direction)
	var attack_right = Vector2(pos.x + 1, pos.y + direction)
	
	return square_pos == attack_left or square_pos == attack_right
