extends Node2D

signal square_clicked(x, y)
signal square_hovered(x, y)

const BOARD_SIZE = 8
var squares = []  # 2D array to store references to chess square nodes

# Called when the node enters the scene tree
func _ready():
	# Initialize empty squares array
	squares = []
	for i in range(BOARD_SIZE):
		squares.append([])
		for j in range(BOARD_SIZE):
			squares[i].append(null)
	
	# Create the chess squares
	create_chess_squares()

# Create all the chess squares
func create_chess_squares():
	# Load the chess square scene
	var square_scene = load("res://scenes/chess_square.tscn")

	# Get the board sprite size and position
	var board_size = $ChessBoardSprite.texture.get_size()
	var board_pos = $ChessBoardSprite.position

	# Calculate the actual square size based on the board texture
	var actual_square_size = (board_size.x - 32) / 8  # 32 pixels for borders (16px on each side)

	# Create all 64 squares
	for x in range(BOARD_SIZE):
		for y in range(BOARD_SIZE):
			# Calculate position
			var pos_x = board_pos.x - board_size.x/2 + 16 + x * actual_square_size + actual_square_size/2
			var pos_y = board_pos.y - board_size.y/2 + 16 + y * actual_square_size + actual_square_size/2

			# Instance the square scene
			var square = square_scene.instantiate()
			square.init(x, y)
			square.position = Vector2(pos_x, pos_y)

			# Adjust the collision shape to match the actual square size
			var collision = square.get_node("CollisionShape2D")
			collision.shape.size = Vector2(actual_square_size, actual_square_size)

			# Same for the visual rect if it exists
			if square.has_node("ColorRect"):
				var rect = square.get_node("ColorRect")
				rect.size = Vector2(actual_square_size, actual_square_size)
				rect.position = Vector2(-actual_square_size/2, -actual_square_size/2)

			# Connect signals
			if not square.is_connected("square_clicked", _on_square_clicked):
				square.square_clicked.connect(_on_square_clicked)
			if not square.is_connected("square_hovered", _on_square_hovered):
				square.square_hovered.connect(_on_square_hovered)

			# Add to the scene
			$Squares.add_child(square)

			# Store reference
			squares[x][y] = square

# Convert board position (0-7, 0-7) to screen coordinates
func board_to_screen(x, y):
	if x >= 0 and x < 8 and y >= 0 and y < 8 and squares[x][y]:
		return squares[x][y].position

	# Fallback using calculation
	var board_pos = $ChessBoardSprite.position
	var board_size = $ChessBoardSprite.texture.get_size()
	var square_size = get_square_size()

	# Calculate from center of board
	var screen_x = board_pos.x - board_size.x/2 + 16 + x * square_size + square_size/2
	var screen_y = board_pos.y - board_size.y/2 + 16 + y * square_size + square_size/2

	return Vector2(screen_x, screen_y)

# Calculate square size more reliably
func get_square_size():
	var board_size = $ChessBoardSprite.texture.get_size()
	# If your board is 288x288 with 16px borders on each side
	return (board_size.x - 32) / 8  # 8 squares per row/column

# Handle square clicks
func _on_square_clicked(x, y):
	print("BoardView: Square clicked at ", x, ", ", y)  # Debug output
	square_clicked.emit(x, y)

# Handle square hover
func _on_square_hovered(x, y):
	# Emit signal for others to handle
	square_hovered.emit(x, y)

# Methods for highlighting squares
func highlight_square(x, y, enable=true):
	if x >= 0 and x < 8 and y >= 0 and y < 8:
		if enable:
			# Green highlight for valid moves
			squares[x][y].highlight(true)
		else:
			squares[x][y].highlight(false)

func highlight_special_square(x, y, color=Color(0.2, 0.6, 0.9, 0.4)):
	if x >= 0 and x < 8 and y >= 0 and y < 8:
		if squares[x][y].has_node("ColorRect"):
			squares[x][y].get_node("ColorRect").color = color
			squares[x][y].get_node("ColorRect").visible = true

func highlight_selected_square(x, y):
	if x >= 0 and x < 8 and y >= 0 and y < 8:
		# Yellow highlight for selected square
		squares[x][y].highlight_selected()

func highlight_capture_square(x, y):
	if x >= 0 and x < 8 and y >= 0 and y < 8:
		# Red highlight for capture moves
		squares[x][y].highlight_capture()

func highlight_check_square(x, y):
	if x >= 0 and x < 8 and y >= 0 and y < 8:
		print("Highlighting check square at", x, ", ", y)
		# Bright red highlight for check
		squares[x][y].highlight_check()

# Clear all highlights
func clear_all_highlights():
	for x in range(BOARD_SIZE):
		for y in range(BOARD_SIZE):
			squares[x][y].highlight(false)
