extends Area2D  # Changed from Node2D to Area2D for collision detection

signal square_clicked(x, y)
signal square_hovered(x, y)

var board_x = 0
var board_y = 0
var is_highlighted = false

func _ready():
	# Connect signals for mouse interaction
	if not is_connected("input_event", _on_input_event):
		input_event.connect(_on_input_event)
	if not is_connected("mouse_entered", _on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)

func init(x, y):
	board_x = x
	board_y = y

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("CHESS SQUARE: Clicked at position ", board_x, ", ", board_y)
			square_clicked.emit(board_x, board_y)

func _on_mouse_entered():
	square_hovered.emit(board_x, board_y)

func highlight(enable):
	is_highlighted = enable

	if is_highlighted:
		# Green highlight for valid moves
		$ColorRect.color = Color(0, 1, 0, 0.3)
		$ColorRect.visible = true
	else:
		$ColorRect.visible = false

func highlight_selected():
	# Yellow highlight for selected square
	$ColorRect.color = Color(1, 1, 0, 0.5)
	$ColorRect.visible = true
	is_highlighted = true

func highlight_capture():
	# Red highlight for capture moves
	$ColorRect.color = Color(1, 0, 0, 0.3)
	$ColorRect.visible = true
	is_highlighted = true

# Highlight king in check with bright red
func highlight_check():
	# Bright red highlight for check
	$ColorRect.color = Color(1, 0, 0, 0.5)  # More opaque red for emphasis
	$ColorRect.visible = true
	is_highlighted = true
