extends Node

signal placement_mode_changed(active)
signal unit_selected(unit_type, is_white) 
signal unit_placed(unit_type, is_white, x, y)
signal unit_removed(x, y)
signal selection_changed(unit_type, is_white)

# Selected unit info
var selected_unit_type = null
var selected_is_white = false
var placement_mode = false

# Reference to components
var chess_board = null
var unit_placer = null
var chess_logic = null

func _ready():
	# Wait a frame for other nodes to initialize
	await get_tree().process_frame
	
	# Find the chess board
	chess_board = get_node("/root").find_child("ChessBoard", true, false)
	
	if chess_board:
		# Find the components
		unit_placer = chess_board.get_node_or_null("UnitPlacer")
		chess_logic = chess_board.get_node_or_null("ChessLogic")
		print("PlacementManager: Found references - UnitPlacer:", unit_placer != null, ", ChessLogic:", chess_logic != null)
	else:
		push_error("ERROR: ChessBoard not found in placement_manager.gd")

	# Listen for right-click to cancel selection
	set_process_input(true)

# Handle input events
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			clear_selection()

# Select a unit type
func select_unit(unit_type, is_white):
	selected_unit_type = unit_type
	selected_is_white = is_white
	placement_mode = true

	print("PlacementManager: Selected unit: ", unit_type, " (", "white" if is_white else "black", ")")

	selection_changed.emit(unit_type, is_white)
	placement_mode_changed.emit(true)

# Clear current selection
func clear_selection():
	if selected_unit_type != null:
		selected_unit_type = null
		placement_mode = false

		print("PlacementManager: Unit selection cleared")

		selection_changed.emit(null, false)
		placement_mode_changed.emit(false)

		# Also clear the selection in the UnitSelector if it exists
		var unit_selector = get_node("/root").find_child("UnitSelector", true, false)
		if unit_selector and unit_selector.has_method("clear_selection"):
			unit_selector.clear_selection()

# Check if placement mode is active
func is_placement_active():
	return placement_mode

# Place the selected unit at the specified board position
func place_unit(x, y):
	if not placement_mode or not selected_unit_type:
		print("PlacementManager: Cannot place unit - conditions not met")
		if not placement_mode:
			print("- Placement mode is off")
		if not selected_unit_type:
			print("- No unit type selected")
		return false

	print("PlacementManager: Placing ", selected_unit_type, " at ", x, ", ", y)

	# Use the UnitPlacer to create and place the unit if available
	if unit_placer:
		var unit = unit_placer.create_unit(selected_unit_type, selected_is_white, x, y)
		if unit:
			unit_placed.emit(selected_unit_type, selected_is_white, x, y)
			return true
	# Fallback if UnitPlacer not available
	elif chess_logic:
		print("PlacementManager: Using fallback placement method")
		# Try to find the manual unit creation function
		var game_controller = chess_board.get_node_or_null("GameController")
		if game_controller:
			# Temporarily disable game_initialized to prevent check detection
			var was_initialized = game_controller.game_initialized
			game_controller.game_initialized = false
			
			# Load the unit scene
			var unit_scene = load("res://scenes/units/" + selected_unit_type.to_lower() + ".tscn")
			if unit_scene:
				var unit = unit_scene.instantiate()
				
				# Find the Units node to parent
				var units_node = chess_board.get_node_or_null("BoardView/Units")
				if units_node:
					units_node.add_child(unit)
					
					# Find BoardView to get screen position
					var board_view = chess_board.get_node_or_null("BoardView")
					if board_view:
						var screen_pos = board_view.board_to_screen(x, y)
						unit.initialize(selected_is_white, Vector2(x, y), chess_logic.board, selected_unit_type)
						unit.position = screen_pos
						
						# Update the board in chess_logic
						chess_logic.place_unit(unit, x, y)
						
						# Restore game_initialized
						game_controller.game_initialized = was_initialized
						
						unit_placed.emit(selected_unit_type, selected_is_white, x, y)
						return true
			
			# Restore game_initialized if we didn't return
			game_controller.game_initialized = was_initialized
	
	print("ERROR: Could not place unit - no placement method available")
	return false

# Remove a unit at the specified position
func remove_unit_at(x, y):
	print("PlacementManager: Removing unit at ", x, ", ", y)
	
	# Try to use UnitPlacer if available
	if unit_placer:
		if unit_placer.remove_unit(x, y):
			unit_removed.emit(x, y)
			return true
	
	return false
