extends Node2D

var army_budget = preload("res://scripts/ui/army_budget.gd").new()
var placement_manager
var chess_board
var valid_rows = [5, 6, 7]  # Only allow placing on these rows (first 3 rows for white)

@onready var budget_label = $CanvasLayer/UI/VBoxContainer/BudgetLabel
@onready var warning_label = $CanvasLayer/UI/VBoxContainer/WarningLabel
@onready var save_button = $CanvasLayer/UI/VBoxContainer/SaveButton
@onready var army_name_input = $CanvasLayer/UI/VBoxContainer/ArmyNameInput

var has_king = false

func _ready():
	# Add the budget script as a child so it processes
	add_child(army_budget)

	# Get references
	chess_board = $ChessBoard
	placement_manager = $PlacementManager

	# Setup UI
	budget_label.text = "Budget: " + str(army_budget.current_budget)
	warning_label.text = "Warning: Army needs a king!"
	warning_label.add_theme_color_override("font_color", Color.RED)

	# Connect signals
	$CanvasLayer/UI/VBoxContainer/SaveButton.pressed.connect(_on_Save_pressed)
	$CanvasLayer/UI/VBoxContainer/ClearButton.pressed.connect(_on_Clear_pressed)
	$CanvasLayer/UI/VBoxContainer/BackButton.pressed.connect(_on_Back_pressed)

	# Connect budget signals
	army_budget.budget_updated.connect(_on_budget_updated)
	army_budget.king_status_changed.connect(_on_king_status_changed)

	# Connect to placement manager
	if placement_manager:
		if not placement_manager.is_connected("unit_placed", Callable(self, "_on_unit_placed")):
			placement_manager.unit_placed.connect(_on_unit_placed)
		if not placement_manager.is_connected("unit_removed", Callable(self, "_on_unit_removed")):
			placement_manager.unit_removed.connect(_on_unit_removed)
		placement_manager.placement_mode = true
	else:
		print("ERROR: PlacementManager not found")

	# Set up initial board state
	setup_initial_board()

func setup_initial_board():
	# Clear existing pieces
	clear_board()

	# Setup standard white pieces - Using the game controller
	if chess_board and chess_board.has_node("GameController"):
		var game_controller = chess_board.get_node("GameController")
		# Let the game controller handle the setup
		await game_controller.start_game()
		
		# Now add all the units to the budget tracking
		update_budget_from_board()
	else:
		print("ERROR: GameController not found in ChessBoard")

# Update budget based on units placed on the board
func update_budget_from_board():
	# Clear the current budget tracking
	army_budget.reset_budget()
	
	# Find the chess logic to get the board state
	var chess_logic = null
	if chess_board and chess_board.has_node("ChessLogic"):
		chess_logic = chess_board.get_node("ChessLogic")
	
	if not chess_logic:
		print("ERROR: ChessLogic not found when updating budget")
		return
		
	# Go through all positions and add units to budget
	for x in range(8):
		for y in range(8):
			var unit = chess_logic.get_unit_at(x, y)
			if unit and unit.is_white and unit.unit_type:
				army_budget.add_unit(unit.unit_type, Vector2(x, y))

func _on_unit_placed(unit_type, is_white, x, y):
	# Only allow placement in the first 3 rows (rows 5-7)
	if not y in valid_rows:
		# Remove the piece that was just placed
		remove_unit_at(x, y)
		return false

	# Check if we can afford this unit
	var pos = Vector2(x, y)
	if not army_budget.add_unit(unit_type, pos):
		# Can't afford, remove the piece
		remove_unit_at(x, y)
		warning_label.text = "Not enough budget for " + unit_type
		return false

	return true

# Simplified unit removal that doesn't rely directly on UnitPlacer
func remove_unit_at(x, y):
	if placement_manager:
		placement_manager.remove_unit_at(x, y)

func _on_unit_removed(x, y):
	var pos = Vector2(x, y)
	army_budget.remove_unit(pos)

func _on_budget_updated(new_amount):
	budget_label.text = "Budget: " + str(new_amount)

func _on_king_status_changed(has_king):
	self.has_king = has_king
	if has_king:
		warning_label.text = ""
	else:
		warning_label.text = "Warning: Army needs a king!"
	save_button.disabled = !has_king

func _on_Save_pressed():
	if !has_king:
		warning_label.text = "Cannot save: Army needs a king!"
		return

	if army_name_input.text.strip_edges() == "":
		warning_label.text = "Please enter an army name"
		return

	# Format the data
	var army_data = {}
	var units = army_budget.get_placed_units()

	for pos in units:
		# Store as string representation of Vector2
		var pos_str = str(pos)
		army_data[pos_str] = units[pos]

	# Save to file
	var file = FileAccess.open("user://army_" + army_name_input.text.strip_edges() + ".json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(army_data))
		file.close()

		warning_label.add_theme_color_override("font_color", Color.GREEN)
		warning_label.text = "Army saved successfully!"
		await get_tree().create_timer(1.5).timeout
		warning_label.add_theme_color_override("font_color", Color.RED)
		warning_label.text = ""
	else:
		warning_label.text = "Error: Could not save army!"

func _on_Clear_pressed():
	clear_board()
	army_budget.reset_budget()

func clear_board():
	# Clear the board using the game controller
	if chess_board and chess_board.has_node("GameController"):
		var game_controller = chess_board.get_node("GameController")
		if game_controller.has_method("start_game"):
			game_controller.start_game()
	else:
		print("ERROR: Could not find GameController for clearing board")

func _on_Back_pressed():
	# Return to main menu
	if placement_manager:
		placement_manager.placement_mode = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
