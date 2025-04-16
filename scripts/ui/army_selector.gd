extends Control

var selected_army = ""
var army_data = null
@onready var army_list = $VBoxContainer/ScrollContainer/ArmyList
@onready var play_button = $VBoxContainer/HBoxContainer/PlayButton

func _ready():
	# Disable play button until an army is selected
	play_button.disabled = true
	
	# Connect signals (Godot 4 syntax)
	$VBoxContainer/HBoxContainer/BackButton.pressed.connect(_on_Back_pressed)
	play_button.pressed.connect(_on_Play_pressed)
	
	# Load available armies
	load_available_armies()

func load_available_armies():
	# Clear existing entries
	for child in army_list.get_children():
		child.queue_free()
	
	# Check user:// directory for army files (Godot 4 syntax)
	var dir = DirAccess.open("user://")
	if dir:
		dir.list_dir_begin()
		
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.begins_with("army_") and file_name.ends_with(".json"):
				# Create button for this army
				var army_name = file_name.substr(5, file_name.length() - 10)  # Remove "army_" and ".json"
				var button = Button.new()
				button.text = army_name
				button.pressed.connect(_on_Army_selected.bind(file_name, army_name))
				button.custom_minimum_size = Vector2(300, 40)  # rect_min_size is now custom_minimum_size
				army_list.add_child(button)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	# Add a default army option
	var default_button = Button.new()
	default_button.text = "Standard Chess Setup"
	default_button.pressed.connect(_on_Default_selected)
	default_button.custom_minimum_size = Vector2(300, 40)
	army_list.add_child(default_button)

func _on_Army_selected(file_name, army_name):
	selected_army = file_name
	play_button.disabled = false
	
	# Load the army data (Godot 4 syntax)
	var file = FileAccess.open("user://" + file_name, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		file.close()
		
		print("Loaded JSON data: " + text)
		
		var json = JSON.new()
		var error = json.parse(text)
		if error == OK:
			army_data = json.get_data()
			print("Parsed army data successfully")
		else:
			print("JSON parse error: " + json.get_error_message())
			army_data = null

func _on_Default_selected():
	selected_army = "default"
	army_data = null
	play_button.disabled = false
	
	# Update selection visual
	for child in army_list.get_children():
		if child is Button:
			if child.text == "Standard Chess Setup":
				child.add_theme_color_override("font_color", Color.GREEN)
			else:
				child.add_theme_color_override("font_color", Color.WHITE)

func _on_Play_pressed():
	# Store the selected army in a global variable or singleton
	var game_data = {"selected_army": selected_army, "army_data": army_data}
	
	# Create a temporary file to pass data between scenes
	var file = FileAccess.open("user://temp_game_data.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(game_data))
		file.close()
		
		# Change to game scene (Godot 4 syntax)
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_Back_pressed():
	# Return to main menu (Godot 4 syntax)
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
