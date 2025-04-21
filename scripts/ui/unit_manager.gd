extends Node2D

# Constants
const MAX_BUDGET = 100
const WHITE_VALID_ROWS = [5, 6, 7]  # White units' starting rows
const BLACK_VALID_ROWS = [0, 1, 2]  # Black units' starting rows

# References
var board_view
var unit_selector
var selected_unit_type = null
var selected_is_white = true

# UI Elements
@onready var budget_label = $CanvasLayer/UI/VBoxContainer/BudgetLabel
@onready var warning_label = $CanvasLayer/UI/VBoxContainer/WarningLabel
@onready var save_button = $CanvasLayer/UI/VBoxContainer/SaveButton
@onready var army_name_input = $CanvasLayer/UI/VBoxContainer/ArmyNameInput

# Army tracking
var white_budget = MAX_BUDGET  # Separate budget for white
var black_budget = MAX_BUDGET  # Separate budget for black
var placed_units = {}  # {position_str: {type: unit_type, is_white: bool}}
var unit_costs = {}
var has_white_king = false
var has_black_king = false

func _ready():
	# IMPORTANT: Wait a frame to make sure all nodes are loaded
	await get_tree().process_frame
	
	# Get references
	board_view = $BoardView
	unit_selector = $CanvasLayer/UI/UnitSelector
	
	# Connect to board_view signals
	if board_view:
		print("Found BoardView, connecting signals")
		if not board_view.is_connected("square_clicked", _on_board_square_clicked):
			board_view.connect("square_clicked", _on_board_square_clicked)
	else:
		push_error("ERROR: BoardView not found!")
	
	# Connect UI buttons
	$CanvasLayer/UI/VBoxContainer/SaveButton.pressed.connect(_on_Save_pressed)
	$CanvasLayer/UI/VBoxContainer/ClearButton.pressed.connect(_on_Clear_pressed)
	$CanvasLayer/UI/VBoxContainer/BackButton.pressed.connect(_on_Back_pressed)
	
	# Connect to unit_selector
	if unit_selector:
		print("Found UnitSelector, connecting signals")
		unit_selector.connect("unit_selected", _on_unit_selected)
	else:
		push_error("ERROR: UnitSelector not found")
	
	# Setup initial UI
	update_budget_display()
	warning_label.text = "Warning: Both sides need kings!"
	warning_label.add_theme_color_override("font_color", Color.RED)
	save_button.disabled = true
	
	print("UnitManager initialized successfully")

# Update the budget display
func update_budget_display():
	budget_label.text = "W: " + str(white_budget) + " / B: " + str(black_budget)

# Handle clicks from BoardView signal
func _on_board_square_clicked(x, y):
	print("UnitManager: Handling click at", x, y, "with selected unit:", selected_unit_type)
	
	if selected_unit_type == null:
		print("No unit selected, checking if we can remove a unit")
		# If no unit selected, try to remove an existing unit
		remove_unit_at(x, y)
		return
	
	# Check if placement is valid based on row restrictions
	var valid_rows = WHITE_VALID_ROWS if selected_is_white else BLACK_VALID_ROWS
	if not y in valid_rows:
		warning_label.text = "Can only place " + ("white" if selected_is_white else "black") + " units in their starting rows"
		print("Invalid row for", "white" if selected_is_white else "black", "unit:", y)
		return
	
	# If there's already a unit, remove it first
	if has_unit_at(x, y):
		print("Removing existing unit at", x, y)
		remove_unit_at(x, y)
	
	# Check if we can afford this unit using the appropriate budget
	var cost = UnitData.get_unit_cost(selected_unit_type)
	var current_budget = white_budget if selected_is_white else black_budget
	
	if selected_unit_type != "King" and current_budget < cost:
		warning_label.text = "Not enough budget for " + selected_unit_type
		print("Not enough budget for", selected_unit_type, "- needed:", cost, "have:", current_budget)
		return
	
	# Place the unit
	print("PLACING:", selected_unit_type, "at", x, y)
	place_unit(selected_unit_type, selected_is_white, x, y)

# Load unit costs from script files
func load_unit_costs():
	var units_dir = "res://scripts/units/"
	var dir = DirAccess.open(units_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".gd"):
				var unit_type = file_name.get_basename().capitalize()
				var script_path = units_dir + file_name
				var script = load(script_path)
				# Create an instance to access the unit_value
				var instance = script.new()
				if instance.has_method("_ready"):
					instance._ready()
				
				var value = instance.unit_value
				unit_costs[unit_type] = value
				instance.free()
			file_name = dir.get_next()
		dir.list_dir_end()
	
	print("Loaded unit costs:", unit_costs)

# Handle unit selection from selector
func _on_unit_selected(unit_type, is_white):
	print("UnitManager: Selected unit", unit_type, "is_white:", is_white)
	selected_unit_type = unit_type
	selected_is_white = is_white

# Check if there's a unit at a position
func has_unit_at(x, y):
	var pos_str = str(Vector2(x, y))
	return placed_units.has(pos_str)

# Place a unit on the board
func place_unit(unit_type, is_white, x, y):
	print("PLACING:", unit_type, "at", x, y, "(", "white" if is_white else "black", ")")
	
	# Load the unit scene
	var unit_scene = load("res://scenes/units/" + unit_type.to_lower() + ".tscn")
	if not unit_scene:
		push_error("ERROR: Could not load unit scene: " + unit_type)
		return null
	
	# Instance the unit
	var unit = unit_scene.instantiate()
	
	# Get the Units container
	var units_container = board_view.get_node_or_null("Units")
	if not units_container:
		push_error("ERROR: Units container not found")
		unit.queue_free()
		return null
	
	# Add to the scene tree
	units_container.add_child(unit)
	
	# Get the screen position
	var screen_pos = board_view.board_to_screen(x, y)
	
	# Initialize the unit without board reference
	unit.initialize(is_white, Vector2(x, y), null, unit_type)
	
	# Set the position
	unit.position = screen_pos
	
	# Update budget and tracking
	if unit_type != "King":
		if is_white:
			white_budget -= UnitData.get_unit_cost(unit_type)
		else:
			black_budget -= UnitData.get_unit_cost(unit_type)
	
	# Track the unit
	var pos_str = str(Vector2(x, y))
	placed_units[pos_str] = {
		"type": unit_type,
		"is_white": is_white
	}
	
	# Update king status
	if unit_type == "King":
		if is_white:
			has_white_king = true
		else:
			has_black_king = true
		update_king_status()
	
	# Update UI
	update_budget_display()
	
	print("Successfully placed", unit_type, "at", x, y)
	return unit

# Remove a unit at a position
func remove_unit_at(x, y):
	var pos_str = str(Vector2(x, y))
	if not placed_units.has(pos_str):
		print("No unit found in tracking data at", x, y)
		return false
	
	var unit_info = placed_units[pos_str]
	var unit_type = unit_info.type
	var is_white = unit_info.is_white
	
	# Find and remove the unit from the scene
	var units_container = board_view.get_node("Units")
	if not units_container:
		push_error("ERROR: Units container not found")
		return false
		
	for unit in units_container.get_children():
		if unit.board_position.x == x and unit.board_position.y == y:
			# Refund the cost (except for kings)
			if unit_type != "King":
				if is_white:
					white_budget += UnitData.get_unit_cost(unit_type)
				else:
					black_budget += UnitData.get_unit_cost(unit_type)
			
			# Update king status
			if unit_type == "King":
				if is_white:
					has_white_king = false
				else:
					has_black_king = false
				update_king_status()
			
			# Remove from scene and tracking
			unit.queue_free()
			placed_units.erase(pos_str)
			
			# Update UI
			update_budget_display()
			print("Removed unit at", x, ",", y)
			return true
	
	print("No unit found in scene at", x, ",", y)
	return false

# Update king status warning
func update_king_status():
	if has_white_king and has_black_king:
		warning_label.text = ""
		save_button.disabled = false
	else:
		if !has_white_king and !has_black_king:
			warning_label.text = "Warning: Both sides need kings!"
		elif !has_white_king:
			warning_label.text = "Warning: White needs a king!"
		else:
			warning_label.text = "Warning: Black needs a king!"
		save_button.disabled = true

# Clear the entire board
func clear_board():
	print("Clearing board")
	
	# Find the Units container
	var units_container = board_view.get_node_or_null("Units")
	if not units_container:
		push_error("ERROR: Units container not found")
		return
		
	# Remove all unit nodes
	for child in units_container.get_children():
		child.queue_free()
	
	# Reset tracking variables
	placed_units.clear()
	white_budget = MAX_BUDGET
	black_budget = MAX_BUDGET
	has_white_king = false
	has_black_king = false
	
	# Update UI
	update_budget_display()
	update_king_status()

# Handle save button press
func _on_Save_pressed():
	if !has_white_king or !has_black_king:
		warning_label.text = "Cannot save: Both sides need a king!"
		return
	if army_name_input.text.strip_edges() == "":
		warning_label.text = "Please enter an army name"
		return
	
	# Format the data - separate white and black units
	var army_data = {
		"white": {},
		"black": {}
	}
	
	for pos_str in placed_units:
		var unit_info = placed_units[pos_str]
		var unit_type = unit_info.type
		var is_white = unit_info.is_white
		
		# Store in the appropriate side
		if is_white:
			army_data.white[pos_str] = unit_type
		else:
			army_data.black[pos_str] = unit_type
	
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

# Handle clear button press
func _on_Clear_pressed():
	clear_board()

# Handle back button press
func _on_Back_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
