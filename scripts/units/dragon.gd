extends BaseUnit

func _ready():
	unit_type = "Dragon"  # This must match your sprite filename
	unit_value = 14  # As per Chess 100 rules

# Get the basic movement pattern
func get_movement_pattern():
	ensure_board_reference()
	if not board:
		return []
		
	var moves = []
	var pos = board_position
	
	# Dragon moves like a rook (horizontally and vertically)
	var rook_directions = [
		Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)
	]
	
	for dir in rook_directions:
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
	
	# Dragon can also move one square diagonally
	var diagonal_directions = [
		Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1), Vector2(1, -1)
	]
	
	for dir in diagonal_directions:
		var target = Vector2(pos.x + dir.x, pos.y + dir.y)
		
		if is_on_board(target) and (is_empty(target) or is_enemy_unit(target)):
			moves.append(target)
	
	return moves

# Dragon attacks the same squares it can move to
func can_attack_square(square_pos):
	# Must be on board and not the same position
	if not is_on_board(square_pos) or square_pos == board_position:
		return false
	
	# Check if square is adjacent diagonally
	var dx = abs(square_pos.x - board_position.x)
	var dy = abs(square_pos.y - board_position.y)
	
	if dx == 1 and dy == 1:
		return true
	
	# Check if dragon can attack along any horizontal or vertical line
	if square_pos.x == board_position.x or square_pos.y == board_position.y:
		# Moving along rank or file
		var dir_x = 0 if square_pos.x == board_position.x else (1 if square_pos.x > board_position.x else -1)
		var dir_y = 0 if square_pos.y == board_position.y else (1 if square_pos.y > board_position.y else -1)
		
		# Check for obstacles
		var current = Vector2(board_position.x, board_position.y)
		while true:
			current = Vector2(current.x + dir_x, current.y + dir_y)
			
			if current == square_pos:
				return true
				
			if not is_empty(current):
				return false
	
	return false
