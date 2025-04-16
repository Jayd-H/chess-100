extends BaseUnit

func _ready():
	unit_type = "Guard"
	unit_value = 4

func get_movement_pattern():
	ensure_board_reference()
	if not board:
		return []
		
	var moves = []
	
	# Find the king's position
	var king_pos = find_friendly_king()
	if not king_pos:
		return moves  # No valid moves if king not found
	
	# Check all positions within a 5x5 grid around the king (2 squares in each direction)
	for x in range(king_pos.x - 2, king_pos.x + 3):
		for y in range(king_pos.y - 2, king_pos.y + 3):
			var target = Vector2(x, y)
			
			# Skip if position is off the board or is current position
			if not is_on_board(target) or target == board_position:
				continue
			
			# Check if the position is at most one square away from current position
			var move_dx = abs(target.x - board_position.x)
			var move_dy = abs(target.y - board_position.y)
			
			# Guards can only move one square at a time (diagonal or orthogonal)
			if move_dx > 1 or move_dy > 1:
				continue
			
			# For captures, only allow diagonal moves
			if not is_empty(target):
				# If not empty, check if it's an enemy and if move is diagonal
				var is_diagonal = move_dx == 1 and move_dy == 1
				if is_enemy_unit(target) and is_diagonal:
					moves.append(target)
			else:
				# For non-captures, allow one-square moves in any direction
				moves.append(target)
	
	return moves

# Find friendly king
func find_friendly_king():
	for x in range(8):
		for y in range(8):
			if board[x][y] != null and board[x][y].unit_type == "King" and board[x][y].is_white == is_white:
				return Vector2(x, y)
	return null

# For check detection
func can_attack_square(square_pos):
	ensure_board_reference()
	if not board:
		return false
	
	# Guard can only attack diagonally and one square at a time
	var dx = abs(square_pos.x - board_position.x)
	var dy = abs(square_pos.y - board_position.y)
	if dx != 1 or dy != 1:  # Must be diagonal (both dx and dy must be 1)
		return false
	
	# Find the king
	var king_pos = find_friendly_king()
	if not king_pos:
		return false
	
	# Check if the attack square is within 2 squares of the king in any direction
	var king_dx = abs(square_pos.x - king_pos.x)
	var king_dy = abs(square_pos.y - king_pos.y)
	return king_dx <= 2 and king_dy <= 2  # Within 5x5 grid centered on king
