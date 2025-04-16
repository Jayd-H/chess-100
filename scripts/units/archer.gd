extends BaseUnit

func _ready():
	unit_type = "Archer"  # This must match your sprite filename
	unit_value = 12  # As per Chess 100 rules

# Get the basic movement pattern
func get_movement_pattern():
	ensure_board_reference()
	if not board:
		return []
		
	var moves = []
	var pos = board_position
	
	# MOVEMENT: Archer moves one square orthogonally (like a rook, but just 1 square)
	var rook_directions = [
		Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)
	]
	
	# Add normal move squares (one square in orthogonal directions)
	for dir in rook_directions:
		var target = Vector2(pos.x + dir.x, pos.y + dir.y)
		
		if is_on_board(target) and is_empty(target):
			moves.append(target)
	
	# CAPTURE: Archer can capture up to 3 squares away, and can jump over pieces
	for dir in rook_directions:
		for distance in range(1, 4):  # 1, 2, or 3 squares away
			var target = Vector2(pos.x + dir.x * distance, pos.y + dir.y * distance)
			
			if not is_on_board(target):
				break  # Off the board
				
			if is_enemy_unit(target):
				moves.append(target)  # Can capture enemy - even by jumping over other pieces!
				break  # Once we capture, we stop in this direction
			
			if is_friendly_unit(target):
				continue  # Jump over friendly unit, keep looking for enemies
	
	return moves

# Archer can attack orthogonally up to 3 squares away, jumping over other pieces
func can_attack_square(square_pos):
	# Must be on board and not the same position
	if not is_on_board(square_pos) or square_pos == board_position:
		return false
		
	var dx = square_pos.x - board_position.x
	var dy = square_pos.y - board_position.y
	
	# Must be orthogonal (along a rank or file)
	if dx != 0 and dy != 0:
		return false  # Not orthogonal
		
	# Calculate distance
	var distance = abs(dx) + abs(dy)  # For orthogonal moves, this is the correct distance
	
	# Must be within range (1-3 squares)
	if distance > 3:
		return false
	
	# Archers can jump over pieces when attacking, so no need to check for obstacles
	return true
