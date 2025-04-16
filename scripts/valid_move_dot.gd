extends Node2D

func _ready():
	# Create a more visible circle indicator
	var dot = ColorRect.new()
	dot.size = Vector2(16, 16)  # Slightly larger dot
	dot.position = Vector2(-8, -8)  # Center it
	dot.color = Color(0.2, 0.8, 0.2, 0.7)  # More opaque green
	add_child(dot)
	
	# Create a pulsing animation
	var tween = create_tween()
	tween.tween_property(dot, "scale", Vector2(0.8, 0.8), 0.5)
	tween.tween_property(dot, "scale", Vector2(1.2, 1.2), 0.5)
	tween.set_loops()  # Make it loop indefinitely
	
	# Make the dot a perfect circle
	dot.set_script(GDScript.new())
	dot.script.source_code = """
extends ColorRect

func _draw():
	var center = size/2
	var radius = min(size.x, size.y)/2
	draw_circle(center, radius, color)
	
func _ready():
	# Make the ColorRect itself transparent
	color = Color(0, 0, 0, 0)
"""
	dot.script.reload()
