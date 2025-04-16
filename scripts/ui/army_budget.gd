extends Node

const MAX_BUDGET = 100
const UNITS_DIR = "res://scripts/units/"

var unit_costs = {}  # Will be populated dynamically
var current_budget = MAX_BUDGET
var placed_units = {}  # Dictionary to track placed units: {position: unit_type}

signal budget_updated(new_amount)
signal king_status_changed(has_king)

func _ready():
	# Load unit costs from script files
	load_unit_costs()

	# Initialize budget
	reset_budget()

	# Debug output
	print("Loaded unit costs: ", unit_costs)

# Dynamically load unit costs from script files
func load_unit_costs():
	var dir = DirAccess.open(UNITS_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(".gd"):
				var unit_type = file_name.get_basename().capitalize()
				var script_path = UNITS_DIR + file_name
				var script = load(script_path)

				# Create an instance to access the unit_value
				var instance = script.new()
				# Some units set unit_value in _ready(), so call it
				if instance.has_method("_ready"):
					instance._ready()

				# Get the unit value 
				var value = instance.unit_value
				unit_costs[unit_type] = value

				# Clean up the temporary instance
				instance.free()

			file_name = dir.get_next()

		dir.list_dir_end()
	else:
		push_error("An error occurred when trying to access unit scripts directory.")

func reset_budget():
	current_budget = MAX_BUDGET
	placed_units.clear()
	budget_updated.emit(current_budget)
	king_status_changed.emit(false)

func add_unit(unit_type, position):
	# If there's already a unit at this position, remove it first
	if placed_units.has(position):
		remove_unit(position)

	# Check if we have this unit type cost loaded
	if not unit_costs.has(unit_type):
		push_error("Unknown unit type: " + unit_type)
		return false

	# Calculate new budget
	var cost = unit_costs[unit_type]
	if current_budget >= cost or unit_type == "King":
		# Special case for King (required but doesn't cost points)
		if unit_type != "King":
			current_budget -= cost

		# Add unit to tracking dictionary
		placed_units[position] = unit_type

		# Emit signals
		budget_updated.emit(current_budget)
		if unit_type == "King":
			king_status_changed.emit(true)

		return true
	return false

func remove_unit(position):
	if placed_units.has(position):
		var unit_type = placed_units[position]

		# Refund the cost
		if unit_type != "King":
			current_budget += unit_costs[unit_type]

		# Remove from tracking
		placed_units.erase(position)

		# Check if king was removed
		var has_king = false
		for type in placed_units.values():
			if type == "King":
				has_king = true
				break

		# Emit signals
		budget_updated.emit(current_budget)
		king_status_changed.emit(has_king)

		return true
	return false

func has_king():
	for type in placed_units.values():
		if type == "King":
			return true
	return false

func get_placed_units():
	return placed_units.duplicate()

func load_army(army_data):
	reset_budget()

	var has_king_flag = false
	for pos_str in army_data.keys():
		var unit_type = army_data[pos_str]

		# Parse Vector2 from string - Godot 4 way
		var pos_array = pos_str.trim_prefix("(").trim_suffix(")").split(", ")
		var pos = Vector2(float(pos_array[0]), float(pos_array[1]))

		if unit_type == "King":
			has_king_flag = true

		if unit_type != "King" and unit_costs.has(unit_type):
			current_budget -= unit_costs[unit_type]

		placed_units[pos] = unit_type

	budget_updated.emit(current_budget)
	king_status_changed.emit(has_king_flag)
