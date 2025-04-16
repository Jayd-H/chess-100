extends BaseUnit
func _ready():
	unit_type = "Knight"  # This must match your sprite filename
	unit_value = 6  # As per Chess 100 rules

# Get the basic movement pattern
func get_movement_pattern():
	ensure_board_reference()
	if not board:
		return []
		
	var moves = []
	var pos = board_position
	
	# Knight moves in L-shape: 2 squares in one direction and 1 square perpendicular
	var offsets = [
		Vector2(1, 2), Vector2(2, 1), Vector2(2, -1), Vector2(1, -2),
		Vector2(-1, -2), Vector2(-2, -1), Vector2(-2, 1), Vector2(-1, 2)
	]
	
	for offset in offsets:
		var target = Vector2(pos.x + offset.x, pos.y + offset.y)
		
		if is_on_board(target) and (is_empty(target) or is_enemy_unit(target)):
			moves.append(target)
	
	return moves

# Knight attacks the same squares it can move to
# Knights can also jump over pieces, so checking is simpler
func can_attack_square(square_pos):
	# Must be on board
	if not is_on_board(square_pos):
		return false
		
	# Knight's L-move pattern
	var dx = abs(square_pos.x - board_position.x)
	var dy = abs(square_pos.y - board_position.y)
	
	# A knight's move is valid if the sum of differences is 3
	# and neither difference is 0 (one must be 1, the other must be 2)
	return (dx + dy == 3) and dx != 0 and dy != 0
