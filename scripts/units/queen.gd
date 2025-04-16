extends BaseUnit
func _ready():
	unit_type = "Queen"  # This must match your sprite filename
	unit_value = 20  # As per Chess 100 rules

# Get the basic movement pattern
func get_movement_pattern():
	ensure_board_reference()
	if not board:
		return []
		
	var moves = []
	var pos = board_position
	
	# Queen can move in any straight line (horizontal, vertical, diagonal)
	var directions = [
		Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1),  # Horizontal/Vertical
		Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1), Vector2(1, -1)  # Diagonal
	]
	
	for dir in directions:
		var current = Vector2(pos.x, pos.y)
		while true:
			current = Vector2(current.x + dir.x, current.y + dir.y)
			
			if not is_on_board(current):
				break
			
			if is_empty(current):
				moves.append(current)
				continue
			
			if is_enemy_unit(current):
				moves.append(current)
				break
			
			if is_friendly_unit(current):
				break
	
	return moves

# Queen attacks the same squares it can move to
func can_attack_square(square_pos):
	# Must be on board and not the same position as the queen
	if not is_on_board(square_pos) or square_pos == board_position:
		return false
		
	# Check if queen can attack along any straight line
	var dx = square_pos.x - board_position.x
	var dy = square_pos.y - board_position.y
	
	# Check if square is on same row, column, or diagonal
	var is_straight_line = (dx == 0 or dy == 0 or abs(dx) == abs(dy))
	if not is_straight_line:
		return false
		
	# Determine direction to check
	var dir_x = 0 if dx == 0 else (1 if dx > 0 else -1)
	var dir_y = 0 if dy == 0 else (1 if dy > 0 else -1)
	
	# Check if there are any pieces blocking the path
	var current = Vector2(board_position.x, board_position.y)
	while true:
		current = Vector2(current.x + dir_x, current.y + dir_y)
		
		# If we've reached the target square, it can be attacked
		if current == square_pos:
			return true
			
		# If we hit a piece before reaching the target, the path is blocked
		if not is_empty(current):
			return false
	
	# Should never reach here
	return false
