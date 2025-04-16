extends BaseUnit

func _ready():
	unit_type = "Wizard"  # This must match your sprite filename
	unit_value = 14  # As per Chess 100 rules

# Get the basic movement pattern
func get_movement_pattern():
	ensure_board_reference()
	if not board:
		return []
		
	var moves = []
	var pos = board_position
	
	# Wizard can teleport up to 3 squares in any direction
	# It can jump over pieces (since it's teleporting)
	for x_offset in range(-3, 4):
		for y_offset in range(-3, 4):
			# Skip the current position
			if x_offset == 0 and y_offset == 0:
				continue
				
			# Calculate Manhattan distance
			var distance = abs(x_offset) + abs(y_offset)
			
			# Check if this offset is within 3 squares (Manhattan distance)
			if distance > 3:
				continue
				
			var target = Vector2(pos.x + x_offset, pos.y + y_offset)
			
			# Check if the target is on the board
			if not is_on_board(target):
				continue
				
			# For teleport moves (distance > 1), we can't capture but can jump over pieces
			if distance > 1:
				# Only add empty squares for teleport moves (no capture)
				if is_empty(target):
					moves.append(target)
			else:
				# For adjacent moves (distance = 1), we can capture normally
				if is_empty(target) or is_enemy_unit(target):
					moves.append(target)
	
	return moves

# Wizard captures like a king (adjacent squares only)
func can_attack_square(square_pos):
	# Must be on board and not the same position
	if not is_on_board(square_pos) or square_pos == board_position:
		return false
		
	# Wizard can only capture in adjacent squares (like a king)
	var dx = abs(square_pos.x - board_position.x)
	var dy = abs(square_pos.y - board_position.y)
	
	# King-like movement (can only capture in adjacent squares)
	return dx <= 1 and dy <= 1 and (dx != 0 or dy != 0)
