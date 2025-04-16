extends BaseUnit
func _ready():
	unit_type = "Bishop"  # This must match your sprite filename
	unit_value = 8  # As per Chess 100 rules

# Get the basic movement pattern
func get_movement_pattern():
	ensure_board_reference()
	if not board:
		return []
		
	var moves = []
	var pos = board_position
	
	# Bishop can move diagonally
	var directions = [
		Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1), Vector2(1, -1)
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

# Bishop attacks the same squares it can move to
func can_attack_square(square_pos):
	# Must be on board and not the same position as the bishop
	if not is_on_board(square_pos) or square_pos == board_position:
		return false
		
	# Check if bishop can attack along any diagonal
	var dx = square_pos.x - board_position.x
	var dy = square_pos.y - board_position.y
	
	# Check if square is on a diagonal (absolute difference in x and y must be equal)
	if abs(dx) != abs(dy):
		return false
		
	# Determine direction to check
	var dir_x = 1 if dx > 0 else -1
	var dir_y = 1 if dy > 0 else -1
	
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
