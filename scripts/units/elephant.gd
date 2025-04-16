extends BaseUnit
func _ready():
	unit_type = "Elephant"  # This must match your sprite filename (without extension)
	unit_value = 8  # As per Chess 100 rules (same as Bishop)

# Get the basic movement pattern
func get_movement_pattern():
	# Make sure board reference is valid
	ensure_board_reference()
	if not board:
		print("ERROR: No board reference in Elephant")
		return []
	
	var moves = []
	var pos = board_position
	
	# Elephant moves exactly two squares diagonally and cannot jump over pieces
	var diagonals = [
		Vector2(1, 1),   # Up-right
		Vector2(1, -1),  # Down-right
		Vector2(-1, 1),  # Up-left
		Vector2(-1, -1)  # Down-left
	]
	
	for dir in diagonals:
		# Check the intermediate square (1 step in the diagonal)
		var intermediate = Vector2(pos.x + dir.x, pos.y + dir.y)
		
		# If the intermediate square is occupied, elephant can't move in this direction
		if not is_on_board(intermediate) or not is_empty(intermediate):
			continue
		
		# Check the target square (2 steps in the diagonal)
		var target = Vector2(pos.x + dir.x * 2, pos.y + dir.y * 2)
		
		# If target is on board and either empty or contains an enemy
		if is_on_board(target) and (is_empty(target) or is_enemy_unit(target)):
			moves.append(target)
	
	return moves
	
# Elephant attacks the same squares it can move to
func can_attack_square(square_pos):
	# Get movement pattern
	var moves = get_movement_pattern()
	
	# Check if square_pos is in moves
	for move in moves:
		if move == square_pos:
			return true
	
	return false
