extends Node

# Global unit costs accessible from anywhere
var unit_costs = {
	"Archer": 12,
	"Bishop": 8,
	"Cannon": 12,
	"Chancellor": 18,
	"Diplomat": 10,
	"Dragon": 14,
	"Elephant": 8,
	"Guard": 4,
	"King": 0,
	"Knight": 6,
	"Pawn": 4,
	"Queen": 20,
	"Rook": 10,
	"Slime": 20,
	"Wizard": 14
}

func get_unit_cost(unit_type):
	if unit_costs.has(unit_type):
		return unit_costs[unit_type]
	return 9999  # Default high value if not found
