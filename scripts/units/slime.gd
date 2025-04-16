extends BaseUnit

func _ready():
	unit_type = "Slime"
	unit_value = 20

func get_movement_pattern():
	ensure_board_reference()
	if not board:
		return []
		
	var moves = []
	
	# Direction depends on color - white moves up the board (negative y)
	var y_direction = -1 if is_white else 1
	
	# Slime can ONLY start moving in "upward" diagonal directions
	if board_position.x < 7:  # Not on right edge
		add_slime_path(moves, Vector2(1, y_direction))  # Up-right
		
	if board_position.x > 0:  # Not on left edge
		add_slime_path(moves, Vector2(-1, y_direction))  # Up-left
	
	return moves

func add_slime_path(moves, direction):
	var current = board_position
	var reflections = 0
	
	# Keep going until we hit a piece or reflect too many times
	while true:
		# Calculate next position
		var next = Vector2(current.x + direction.x, current.y + direction.y)
		
		# Check if next position is off the board (hit a wall)
		if next.x < 0 or next.x > 7 or next.y < 0 or next.y > 7:
			# We've hit a wall, reflect
			reflections += 1
			
			if reflections > 3:
				return  # Too many reflections
				
			# Determine which wall(s) we hit and reflect accordingly
			if next.x < 0 or next.x > 7:
				direction.x = -direction.x  # Reflect horizontally
				
			if next.y < 0 or next.y > 7:
				direction.y = -direction.y  # Reflect vertically
				
			# Continue with new direction from current position
			continue
		
		# Next position is valid, check for pieces
		if is_empty(next):
			moves.append(next)
			current = next  # Move to this position
		elif is_enemy_unit(next):
			moves.append(next)  # Can capture
			return  # Stop at piece
		else:
			return  # Stop at friendly piece

# For check detection
func can_attack_square(square_pos):
	# Get all possible moves
	var moves = get_movement_pattern()
	
	# Check if the target square is in our movement pattern
	for move in moves:
		if move == square_pos:
			return true
	
	return false
