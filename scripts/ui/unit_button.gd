extends Control

signal white_unit_selected
signal black_unit_selected

var unit_type = "None"
var is_selected = false
var selected_color = null  # "white" or "black" or null

# References to child nodes
var white_button = null
var black_button = null
var unit_label = null

func _ready():
	# Find the buttons and label
	white_button = find_child("WhiteButton", true, false)
	black_button = find_child("BlackButton", true, false)
	unit_label = find_child("UnitLabel", true, false)
	
	# Connect signals if buttons exist
	if white_button:
		white_button.pressed.connect(_on_white_button_pressed)
	
	if black_button:
		black_button.pressed.connect(_on_black_button_pressed)
	
	# Log errors if nodes are missing
	if not white_button:
		print("ERROR: WhiteButton node not found in UnitButton")
	if not black_button:
		print("ERROR: BlackButton node not found in UnitButton")
	if not unit_label:
		print("ERROR: UnitLabel node not found in UnitButton")

# Initialize the button with a unit type
func initialize(type):
	unit_type = type
	
	# Set label text if the label exists
	if unit_label:
		unit_label.text = unit_type
	
	# Load the appropriate sprites
	var white_texture = load("res://assets/sprites/whiteunits/" + unit_type + ".png")
	var black_texture = load("res://assets/sprites/blackunits/" + unit_type + ".png")
	
	# Set button textures if buttons exist
	if white_button and white_texture:
		white_button.texture_normal = white_texture
	
	if black_button and black_texture:
		black_button.texture_normal = black_texture

# Handle white button selection
func _on_white_button_pressed():
	if selected_color == "white":
		# If already selected, deselect
		deselect()
	else:
		# Select white
		is_selected = true
		selected_color = "white"
		update_visual_state()
		emit_signal("white_unit_selected")

# Handle black button selection
func _on_black_button_pressed():
	if selected_color == "black":
		# If already selected, deselect
		deselect()
	else:
		# Select black
		is_selected = true
		selected_color = "black"
		update_visual_state()
		emit_signal("black_unit_selected")

# Force white selection (for white-only mode)
func force_white_selection():
	is_selected = false
	selected_color = null
	update_visual_state()

# Force black selection (for black-only mode)
func force_black_selection():
	is_selected = false
	selected_color = null
	update_visual_state()

# Update the visual appearance based on selection state
func update_visual_state():
	# Reset appearance
	if white_button:
		white_button.modulate = Color(1, 1, 1, 1)
	
	if black_button:
		black_button.modulate = Color(1, 1, 1, 1)
	
	# Highlight the selected button
	if is_selected:
		if selected_color == "white" and white_button:
			white_button.modulate = Color(1.2, 1.2, 0.5)  # Yellowish highlight
		elif selected_color == "black" and black_button:
			black_button.modulate = Color(1.2, 1.2, 0.5)  # Yellowish highlight

# Deselect this button
func deselect():
	is_selected = false
	selected_color = null
	update_visual_state()
