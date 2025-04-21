extends Node

const MAX_BUDGET = 100

var current_budget = MAX_BUDGET
var placed_units = {}  # Dictionary to track placed units: {position: unit_type}

signal budget_updated(new_amount)
signal king_status_changed(has_king)

func _ready():
	reset_budget()

func reset_budget():
	current_budget = MAX_BUDGET
	placed_units.clear()
	budget_updated.emit(current_budget)
	king_status_changed.emit(false)

func add_unit(unit_type, position):
	# If there's already a unit at this position, remove it first
	if placed_units.has(position):
		remove_unit(position)
	
	# Calculate new budget
	var cost = UnitData.get_unit_cost(unit_type)
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
			current_budget += UnitData.get_unit_cost(unit_type)
		
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
		
		if unit_type != "King":
			current_budget -= UnitData.get_unit_cost(unit_type)
		
		placed_units[pos] = unit_type
	
	budget_updated.emit(current_budget)
	king_status_changed.emit(has_king_flag)
