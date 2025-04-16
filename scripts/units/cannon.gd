extends BaseUnit

func _ready():
	unit_type = "Cannon"  # This must match your sprite filename
	unit_value = 12  # As per Chess 100 rules

# Get the basic movement pattern
func get_movement_pattern():
	ensure_board_reference()
	if not board:
		return []
		
	var moves = []
	var pos = board_position
	
	# Cannon moves like a rook for non-capture moves
	var directions = [
		Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)
	]
	
	# Handle normal movement (like a rook, no jumping)
	for dir in directions:
		var current = Vector2(pos.x, pos.y)
		
		while true:
			current = Vector2(current.x + dir.x, current.y + dir.y)
			
			if not is_on_board(current):
				break
			
			if is_empty(current):
				moves.append(current)
				continue
			
			# Stop when we hit any piece (can't jump for non-capture movement)
			break
	
	# Handle captures (must jump exactly one piece)
	for dir in directions:
		var current = Vector2(pos.x, pos.y)
		var jumped = false
		
		while true:
			current = Vector2(current.x + dir.x, current.y + dir.y)
			
			if not is_on_board(current):
				break
				
			if not jumped:
				# Haven't jumped yet
				if is_empty(current):
					continue  # Keep looking for a piece to jump
				else:
					jumped = true  # Found a piece to jump over (platform)
			else:
				# Already jumped over one piece
				if is_empty(current):
					continue  # Keep looking for an enemy to capture
				elif is_enemy_unit(current):
					moves.append(current)  # Can capture this enemy
					break
				else:
					break  # Hit a friendly piece, can't go further
	
	return moves

# Cannon attacks by jumping exactly one piece
func can_attack_square(square_pos):
	# Must be on board and not the same position
	if not is_on_board(square_pos) or square_pos == board_position:
		return false
		
	# Cannon can only attack along ranks and files
	if square_pos.x != board_position.x and square_pos.y != board_position.y:
		return false  # Not on same rank or file
		
	# Determine direction
	var dir_x = 0 if square_pos.x == board_position.x else (1 if square_pos.x > board_position.x else -1)
	var dir_y = 0 if square_pos.y == board_position.y else (1 if square_pos.y > board_position.y else -1)
	
	# Check if there is exactly one piece between cannon and target
	var current = Vector2(board_position.x, board_position.y)
	var pieces_jumped = 0
	
	while true:
		current = Vector2(current.x + dir_x, current.y + dir_y)
		
		if current == square_pos:
			break
			
		if not is_on_board(current):
			return false
			
		if not is_empty(current):
			pieces_jumped += 1
			
		if pieces_jumped > 1:
			return false  # More than one piece between
	
	# Can only attack if there is exactly one piece between
	return pieces_jumped == 1
