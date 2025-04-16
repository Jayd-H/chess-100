extends Panel

signal unit_selected(unit_type, is_white)

# Array of all unit types to display
var unit_types = [
	"Pawn", "Rook", "Knight", "Bishop", "Queen", "King", "Elephant", "Wizard", "Chancellor", "Cannon"
]

# References
var placement_manager = null
var unit_buttons = []
var container = null

func _ready():
	# Find the container
	container = find_child("VBoxContainer", true, false)
	if not container:
		push_error("ERROR: VBoxContainer not found in UnitSelector")
		return
		
	# Get reference to the placement manager
	placement_manager = get_node("/root").find_child("PlacementManager", true, false)
	if not placement_manager:
		print("WARNING: PlacementManager not found, unit placement will not work")
	
	# Create unit buttons
	create_unit_buttons()

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

# Clear all selections
func clear_selection():
	for button in unit_buttons:
		button.deselect()
