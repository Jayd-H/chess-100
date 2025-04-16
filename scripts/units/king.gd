extends BaseUnit

func _ready():
	unit_type = "King"  # This must match your sprite filename (without extension)
	unit_value = 0  # Kings have no point value in Chess 100

# Get the basic movement pattern without checking king safety
func get_movement_pattern():
	# Make sure board reference is valid
	ensure_board_reference()
	if not board:
		print("ERROR: No board reference in King")
		return []
	
	var moves = []
	var pos = board_position
	
	# King can move one square in any direction
	var directions = [
		Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(-1, 1),
		Vector2(-1, 0), Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1)
	]
	
	for dir in directions:
		var target = Vector2(pos.x + dir.x, pos.y + dir.y)
		if is_on_board(target) and (is_empty(target) or is_enemy_unit(target)):
			moves.append(target)
	
	return moves

# Get special moves like castling
func get_special_moves(last_move):
	# Make sure board reference is valid
	ensure_board_reference()
	if not board or has_moved:
		return []
	
	var special_moves = []
	var pos = board_position
	
	# Check if king is already in check - can't castle while in check
	var game_manager = find_game_manager()
	if game_manager and game_manager.is_king_in_check(is_white):
		return []
	
	# Kingside castling
	if int(pos.x) + 3 < 8:  # Make sure we don't go out of bounds
		var kingside_rook_pos = Vector2(7, pos.y)
		if board[7][int(pos.y)] != null and board[7][int(pos.y)].unit_type == "Rook" and not board[7][int(pos.y)].has_moved:
			if is_empty(Vector2(pos.x + 1, pos.y)) and is_empty(Vector2(pos.x + 2, pos.y)):
				# Check if path squares are under attack
				var path_safe = true
				for i in range(1, 3):  # Check squares king moves through
					if is_path_under_attack(Vector2(pos.x + i, pos.y)):
						path_safe = false
						break
				
				if path_safe:
					special_moves.append(Vector2(pos.x + 2, pos.y))
	
	# Queenside castling
	if int(pos.x) - 4 >= 0:  # Make sure we don't go out of bounds
		var queenside_rook_pos = Vector2(0, pos.y)
		if board[0][int(pos.y)] != null and board[0][int(pos.y)].unit_type == "Rook" and not board[0][int(pos.y)].has_moved:
			if is_empty(Vector2(pos.x - 1, pos.y)) and is_empty(Vector2(pos.x - 2, pos.y)) and is_empty(Vector2(pos.x - 3, pos.y)):
				# Check if path squares are under attack
				var path_safe = true
				for i in range(1, 3):  # Check squares king moves through
					if is_path_under_attack(Vector2(pos.x - i, pos.y)):
						path_safe = false
						break
				
				if path_safe:
					special_moves.append(Vector2(pos.x - 2, pos.y))
	
	return special_moves

# Handle special move like castling
func handle_special_move(from_pos, to_pos, last_move, board_ref):
	# Only handle castling
	if abs(from_pos.x - to_pos.x) <= 1:
		return null  # Not castling
	
	# Determine castling direction
	var rook_x = 0
	var new_rook_x = 3
	
	if to_pos.x > from_pos.x:  # Kingside
		rook_x = 7
		new_rook_x = 5
	
	# Move the rook
	var rook = board_ref[rook_x][int(from_pos.y)]
	if rook != null and rook.unit_type == "Rook":
		# Update board array
		board_ref[rook_x][int(from_pos.y)] = null
		board_ref[new_rook_x][int(from_pos.y)] = rook
		
		# Update rook's internal position
		rook.board_position = Vector2(new_rook_x, from_pos.y)
		rook.has_moved = true
		
		# Find the board_view to update visual position
		var board_view = get_node("/root").find_child("BoardView", true, false)
		if board_view and board_view.has_method("board_to_screen"):
			# Update rook's visual position
			rook.position = board_view.board_to_screen(new_rook_x, from_pos.y)
		else:
			print("WARNING: Couldn't find BoardView for castling visual update")
		
		print("King castled successfully, moved rook from", rook_x, "to", new_rook_x)
	
	return null  # Castling doesn't capture a piece

# Override get_valid_moves to filter out moves that would put the king in check
func get_valid_moves():
	var moves = get_movement_pattern()
	
	# Add special moves like castling
	var special_moves = get_special_moves(null)  # No need for last_move here
	for move in special_moves:
		if not move in moves:
			moves.append(move)
	
	var safe_moves = []
	
	var game_manager = find_game_manager()
	if game_manager:
		for move in moves:
			# Check if this move would put the king under attack
			if not would_move_to_attacked_square(move):
				safe_moves.append(move)
	else:
		# If no game manager, just return the raw moves
		return moves
	
	return safe_moves

# Check directly if a square would be under attack
func would_move_to_attacked_square(target_square):
	var game_manager = find_game_manager()
	if game_manager:
		# Check directly if the square is under attack
		return game_manager.is_square_under_attack(target_square, !is_white)
	return false

# Check if a path square is under attack (for castling)
func is_path_under_attack(square_pos):
	var game_manager = find_game_manager()
	if game_manager:
		return game_manager.is_square_under_attack(square_pos, !is_white)
	return false
