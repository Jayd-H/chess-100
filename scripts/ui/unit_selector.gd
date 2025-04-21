extends Panel

signal unit_selected(unit_type, is_white)

# References
var placement_manager = null
var unit_buttons = []
var unit_types = []  # Will be populated automatically

@onready var container: VBoxContainer = $ScrollContainer/VBoxContainer

func _ready():
	# Get reference to the placement manager
	placement_manager = get_node("/root").find_child("PlacementManager", true, false)
	if not placement_manager:
		print("WARNING: PlacementManager not found, unit placement will not work")
	
	# Load all unit types from scripts
	load_unit_types()
	
	# Create unit buttons
	create_unit_buttons()

func load_unit_types():
	unit_types = [
		"King", "Queen", "Rook", "Bishop", "Knight", "Pawn", 
		"Archer", "Cannon", "Chancellor", "Diplomat", "Dragon", 
		"Elephant", "Guard", "Slime", "Wizard"
	]
	
	# Sort the units in a more logical order (your existing code)
	unit_types.sort_custom(func(a, b):
		# Define priority order for standard pieces
		var priority = {
			"King": 0,
			"Queen": 1,
			"Rook": 2, 
			"Bishop": 3,
			"Knight": 4,
			"Pawn": 5
		}
		
		# Check if both are standard pieces
		if priority.has(a) and priority.has(b):
			return priority[a] < priority[b]
		# If only a is standard, it goes first
		elif priority.has(a):
			return true
		# If only b is standard, it goes first
		elif priority.has(b):
			return false
		# Otherwise sort alphabetically
		else:
			return a < b
	)
	
	print("Loaded unit types: ", unit_types)
	
	# Sort the units in a more logical order
	# Put King and Queen first, then standard chess pieces, then others alphabetically
	unit_types.sort_custom(func(a, b):
		# Define priority order for standard pieces
		var priority = {
			"King": 0,
			"Queen": 1,
			"Rook": 2, 
			"Bishop": 3,
			"Knight": 4,
			"Pawn": 5
		}
		
		# Check if both are standard pieces
		if priority.has(a) and priority.has(b):
			return priority[a] < priority[b]
		# If only a is standard, it goes first
		elif priority.has(a):
			return true
		# If only b is standard, it goes first
		elif priority.has(b):
			return false
		# Otherwise sort alphabetically
		else:
			return a < b
	)
	
	print("Loaded unit types: ", unit_types)

func create_unit_buttons():
	if not container:
		return
		
	# Clear any existing buttons
	for child in container.get_children():
		if child.name != "TitleLabel":  # Don't remove the title
			child.queue_free()
	
	unit_buttons.clear()
	
	# Create buttons for each unit type
	for unit_type in unit_types:
		# Create a UnitButton instance
		var unit_button_scene = load("res://scenes/ui/unit_button.tscn")
		if not unit_button_scene:
			push_error("ERROR: Failed to load UnitButton scene")
			continue
			
		var unit_button = unit_button_scene.instantiate()
		
		# Add to container first so _ready is called
		container.add_child(unit_button)
		
		# Initialize with unit type after it's added to the scene
		if unit_button.has_method("initialize"):
			unit_button.initialize(unit_type)
		else:
			push_error("ERROR: UnitButton doesn't have initialize method")
		
		# Connect the button's signals
		if unit_button.has_signal("white_unit_selected"):
			unit_button.white_unit_selected.connect(_on_unit_selected.bind(unit_type, true))
		
		if unit_button.has_signal("black_unit_selected"):
			unit_button.black_unit_selected.connect(_on_unit_selected.bind(unit_type, false))
		
		unit_buttons.append(unit_button)

# Handle unit selection
func _on_unit_selected(unit_type, is_white):
	# Deselect all other buttons
	for button in unit_buttons:
		if button.unit_type != unit_type:
			button.deselect()
	
	# Emit signal for external systems
	unit_selected.emit(unit_type, is_white)
	
	# Inform placement manager if available
	if placement_manager:
		placement_manager.select_unit(unit_type, is_white)
	else:
		push_error("No placement manager available")

# Show only buttons of the specified color
func show_only_color(is_white):
	print("Setting unit selector to show only " + ("WHITE" if is_white else "BLACK") + " pieces")
	
	# COMPLETELY HIDE the opposite color buttons
	for button in unit_buttons:
		# Hide both initially
		if button.has_node("VBoxContainer/HBoxContainer/WhiteButton"):
			button.get_node("VBoxContainer/HBoxContainer/WhiteButton").visible = false
			button.get_node("VBoxContainer/HBoxContainer/WhiteButton").disabled = true
			
		if button.has_node("VBoxContainer/HBoxContainer/BlackButton"):
			button.get_node("VBoxContainer/HBoxContainer/BlackButton").visible = false
			button.get_node("VBoxContainer/HBoxContainer/BlackButton").disabled = true
			
		# Then show only the color we want
		if is_white:
			if button.has_node("VBoxContainer/HBoxContainer/WhiteButton"):
				button.get_node("VBoxContainer/HBoxContainer/WhiteButton").visible = true
				button.get_node("VBoxContainer/HBoxContainer/WhiteButton").disabled = false
		else:
			if button.has_node("VBoxContainer/HBoxContainer/BlackButton"):
				button.get_node("VBoxContainer/HBoxContainer/BlackButton").visible = true
				button.get_node("VBoxContainer/HBoxContainer/BlackButton").disabled = false
	
	# Make sure remaining buttons are centered
	for button in unit_buttons:
		if button.has_node("VBoxContainer/HBoxContainer"):
			button.get_node("VBoxContainer/HBoxContainer").alignment = BoxContainer.ALIGNMENT_CENTER

# Clear all selections
func clear_selection():
	for button in unit_buttons:
		button.deselect()

# Legacy method for compatibility
func set_white_only(white_only):
	show_only_color(white_only)
