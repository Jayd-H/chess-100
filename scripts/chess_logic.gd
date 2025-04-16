extends Node

signal move_made(unit, from_pos, to_pos, is_capture, captured_unit)
signal turn_changed(is_white_turn)
signal check_occurred(is_white_king)
signal checkmate_occurred(is_white_king)
signal stalemate_occurred()

var has_diplomats = false

# Board representation: null = empty, otherwise contains unit reference
var board = []
const BOARD_SIZE = 8

# Game state
var selected_unit = null
var selected_pos = Vector2(-1, -1)
var is_white_turn = true
var last_move = null
var game_over = false

# Flag to prevent infinite recursion during check detection
var checking_for_attacks = false

# Called when the node enters the scene tree
func _ready():
	# Initialize empty 8x8 board
	board = []
	for i in range(BOARD_SIZE):
		board.append([])
		for j in range(BOARD_SIZE):
			board[i].append(null)

# Reset the game state
func reset_game():
	# Clear the board
	for x in range(BOARD_SIZE):
		for y in range(BOARD_SIZE):
			if board[x][y] != null:
				board[x][y] = null
	
	# Reset game state
	selected_unit = null
	selected_pos = Vector2(-1, -1)
	is_white_turn = true
	last_move = null
	game_over = false

# Handle a square click
func handle_square_click(x, y):
	if game_over:
		return false
	
	print("Chess Logic: Square clicked at ", x, ", ", y)
	
	# If no unit is selected, try to select one
	if selected_unit == null:
		var unit = board[x][y]
		if unit != null and unit.is_white == is_white_turn:
			# Select the unit
			selected_unit = unit
			selected_pos = Vector2(x, y)
			print("Selected unit: ", unit.unit_type)
			return true
	
	# If a unit is already selected, try to move it
	else:
		# Check if the target is a valid move
		if is_valid_move(selected_unit, Vector2(x, y)):
			# Make the move
			make_move(selected_unit, selected_pos, Vector2(x, y))
			
			# Clear selections
			selected_unit = null
			selected_pos = Vector2(-1, -1)
			
			# Check game state after move
			check_game_state()
			
			return true
		
		# Or if the player selects another of their units
		elif board[x][y] != null and board[x][y].is_white == is_white_turn:
			# Select new unit
			selected_unit = board[x][y]
			selected_pos = Vector2(x, y)
			print("Selected unit: ", selected_unit.unit_type)
			return true
		
		# Clicking on empty square or opponent's unit when not a valid move
		else:
			# Deselect everything
			selected_unit = null
			selected_pos = Vector2(-1, -1)
			return true
	
	return false

# Get valid moves for the currently selected unit
func get_valid_moves_for_selected():
	if selected_unit == null:
		return []
	
	return get_valid_moves(selected_unit)

# Get valid moves for a specific unit
# Get valid moves for a specific unit
# Get valid moves for a specific unit
func get_valid_moves(unit):
	if unit == null:
		return []
	
	# Make sure the unit has a board reference
	unit.board = board
	
	# Check for special moves if unit has get_special_moves method
	var all_moves = []
	if unit.has_method("get_movement_pattern"):
		all_moves = unit.get_movement_pattern()
	
	# Add special moves if the unit has them
	if unit.has_method("get_special_moves"):
		var special_moves = unit.get_special_moves(last_move)
		for move in special_moves:
			if not move in all_moves:
				all_moves.append(move)
	
	# Filter out captures of diplomat-protected squares
	if has_diplomats:
		var filtered_moves = []
		for move in all_moves:
			var target = board[int(move.x)][int(move.y)]
			if target != null:  # This is a capture move
				# Only check diplomat protection for the target square
				var diplomat_script = load("res://scripts/units/diplomat.gd")
				if diplomat_script and diplomat_script.has_method("is_target_protected_by_diplomat"):
					if diplomat_script.is_target_protected_by_diplomat(move, board):
						continue  # Skip this move - target is protected
			
			filtered_moves.append(move)
		
		all_moves = filtered_moves
	
	# Filter out moves that would leave the king in check
	var legal_moves = []
	for move in all_moves:
		if not would_leave_king_in_check(unit, move):
			legal_moves.append(move)
	
	return legal_moves
	
func is_capture_prevented(from_pos, to_pos):
	# Check if there's a diplomat adjacent to the capturing piece
	var from_x = int(from_pos.x)
	var from_y = int(from_pos.y)
	
	# Scan the board for diplomats of the opposite color to the moving piece
	var attacker = board[from_x][from_y]
	if attacker == null:
		return false
		
	# Only need to check if a capture is being attempted
	var target = board[int(to_pos.x)][int(to_pos.y)]
	if target == null:
		return false  # Not a capture
	
	# Check all surrounding squares for enemy diplomats
	for x_offset in range(-1, 2):
		for y_offset in range(-1, 2):
			if x_offset == 0 and y_offset == 0:
				continue  # Skip the piece's own square
				
			var check_x = from_x + x_offset
			var check_y = from_y + y_offset
			
			# Make sure the position is on the board
			if check_x < 0 or check_x > 7 or check_y < 0 or check_y > 7:
				continue
				
			# Check for a diplomat of the opposite color
			var check_piece = board[check_x][check_y]
			if check_piece != null and check_piece.unit_type == "Diplomat" and check_piece.is_white != attacker.is_white:
				print("Capture prevented by diplomat at ", check_x, ", ", check_y)
				return true  # Capture is prevented
	
	return false  # No diplomat preventing capture

# Check if a move is valid
func is_valid_move(unit, target_pos):
	var moves = get_valid_moves(unit)
	
	# Check if this is a capture move
	if unit != null and board[int(target_pos.x)][int(target_pos.y)] != null:
		# Check for diplomat prevention using static method
		var diplomat_script = load("res://scripts/units/diplomat.gd")
		if diplomat_script and diplomat_script.has_method("prevents_capture"):
			if diplomat_script.prevents_capture(unit.board_position, target_pos, board):
				return false  # Capture prevented by diplomat
	
	return target_pos in moves

# Check if a move would leave the king in check
func would_leave_king_in_check(unit, target_pos):
	# Save original state
	var original_pos = unit.board_position
	var target_unit = board[int(target_pos.x)][int(target_pos.y)]
	
	# Temporarily make the move
	board[int(original_pos.x)][int(original_pos.y)] = null
	board[int(target_pos.x)][int(target_pos.y)] = unit
	
	# Check if king would be in check
	var in_check = is_king_in_check(unit.is_white)
	
	# Restore original state
	board[int(original_pos.x)][int(original_pos.y)] = unit
	board[int(target_pos.x)][int(target_pos.y)] = target_unit
	
	return in_check

# Make a move
func make_move(unit, from_pos, to_pos):
	# Check if this is a regular capture
	var is_capture = board[int(to_pos.x)][int(to_pos.y)] != null
	var captured_unit = board[int(to_pos.x)][int(to_pos.y)]
	
	# Handle special moves
	if unit.has_method("handle_special_move"):
		var special_capture = unit.handle_special_move(from_pos, to_pos, last_move, board)
		if special_capture != null:
			is_capture = true
			captured_unit = special_capture
	
	# Update the board array
	board[int(from_pos.x)][int(from_pos.y)] = null
	board[int(to_pos.x)][int(to_pos.y)] = unit
	
	# Update the unit's position
	unit.board_position = to_pos
	unit.has_moved = true
	
	# Store the last move (important for special moves like en passant)
	last_move = {
		"unit": unit,
		"from": from_pos,
		"to": to_pos
	}
	
	# Switch turns
	is_white_turn = !is_white_turn
	
	# Emit signal
	move_made.emit(unit, from_pos, to_pos, is_capture, captured_unit)
	turn_changed.emit(is_white_turn)
	
	return captured_unit

# Check if a king is in check
func is_king_in_check(is_white_king):
	# Find the king
	var king_pos = find_king(is_white_king)
	if king_pos == null:
		return false
	
	# Check if the king's position is under attack by the opposite color
	var under_attack = is_square_under_attack(king_pos, !is_white_king)
	if under_attack:
		print("King at", king_pos, "is under attack!")
	return under_attack

# Find a king's position
func find_king(is_white_king):
	for x in range(BOARD_SIZE):
		for y in range(BOARD_SIZE):
			var unit = board[x][y]
			if unit != null and unit.unit_type == "King" and unit.is_white == is_white_king:
				return Vector2(x, y)
	return null

# Check if a square is under attack by pieces of a specific color
func is_square_under_attack(square_pos, by_white_player):
	# Prevent infinite recursion
	if checking_for_attacks:
		return false
	
	checking_for_attacks = true
	
	# Go through all units of the attacking color
	for x in range(BOARD_SIZE):
		for y in range(BOARD_SIZE):
			var unit = board[x][y]
			
			# Skip empty squares and pieces of the wrong color
			if unit == null or unit.is_white != by_white_player:
				continue
			
			# Make sure unit has a board reference
			unit.board = board
			
			# Ask the unit if it can attack this square
			if unit.has_method("can_attack_square") and unit.can_attack_square(square_pos):
				checking_for_attacks = false
				return true
	
	checking_for_attacks = false
	return false

# Check for checkmate
func is_checkmate(is_white_player):
	# If not in check, can't be checkmate
	if not is_king_in_check(is_white_player):
		return false
	
	# Try all possible moves for all units
	for x in range(BOARD_SIZE):
		for y in range(BOARD_SIZE):
			var unit = board[x][y]
			if unit == null or unit.is_white != is_white_player:
				continue
			
			var moves = get_valid_moves(unit)
			if moves.size() > 0:
				return false  # If any piece has a valid move, it's not checkmate
	
	# If no piece can make a move that gets out of check, it's checkmate
	return true

# Check for stalemate
func is_stalemate(is_white_player):
	# If in check, can't be stalemate
	if is_king_in_check(is_white_player):
		return false
	
	# Try all possible moves for all units
	for x in range(BOARD_SIZE):
		for y in range(BOARD_SIZE):
			var unit = board[x][y]
			if unit == null or unit.is_white != is_white_player:
				continue
			
			var moves = get_valid_moves(unit)
			if moves.size() > 0:
				return false  # If any piece has a valid move, it's not stalemate
	
	# If no piece can move, it's stalemate
	return true

# Check game state after a move
func check_game_state():
	# Check if current player is in check
	if is_king_in_check(is_white_turn):
		print("Emitting check_occurred signal for player:", "White" if is_white_turn else "Black")
		check_occurred.emit(is_white_turn)
		
		# Check if it's checkmate
		if is_checkmate(is_white_turn):
			game_over = true
			checkmate_occurred.emit(is_white_turn)
	
	# Check for stalemate
	elif is_stalemate(is_white_turn):
		game_over = true
		stalemate_occurred.emit()

# Get the board representation
func get_board():
	return board

# Place a unit on the board
func place_unit(unit, x, y):
	if x >= 0 and x < BOARD_SIZE and y >= 0 and y < BOARD_SIZE:
		board[x][y] = unit
		
		# Check if this is a diplomat
		if unit.unit_type == "Diplomat":
			has_diplomats = true
			
		return true
	return false


# Remove a unit from the board
func remove_unit(x, y):
	if x >= 0 and x < BOARD_SIZE and y >= 0 and y < BOARD_SIZE and board[x][y] != null:
		board[x][y] = null
		return true
	return false

# Get the unit at a specific position
func get_unit_at(x, y):
	if x >= 0 and x < BOARD_SIZE and y >= 0 and y < BOARD_SIZE:
		return board[x][y]
	return null

# Get the last move
func get_last_move():
	return last_move
