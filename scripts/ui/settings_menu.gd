extends Control

# Available resolutions
var resolutions = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

# Configuration file path
const CONFIG_FILE_PATH = "user://settings.cfg"

# UI Elements

@onready var fullscreen_toggle: CheckButton = $CanvasLayer/VBoxContainer/GridContainer/FullscreenToggle
@onready var master_volume_slider: HSlider = $CanvasLayer/VBoxContainer/GridContainer/MasterVolumeSlider
@onready var resolution_dropdown: OptionButton = $CanvasLayer/VBoxContainer/GridContainer/ResolutionDropdown


@onready var back_button: Button = $CanvasLayer/VBoxContainer/ButtonsContainer/BackButton
@onready var apply_button: Button = $CanvasLayer/VBoxContainer/ButtonsContainer/ApplyButton



# Audio buses
var master_bus = AudioServer.get_bus_index("Master")

func _ready():
	# Connect button signals
	apply_button.pressed.connect(_on_apply_pressed)
	back_button.pressed.connect(_on_back_pressed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	
	# Populate resolution dropdown
	for res in resolutions:
		resolution_dropdown.add_item(str(res.x) + "x" + str(res.y))
	
	# Load current settings
	load_settings()

func load_settings():
	var config = ConfigFile.new()
	var err = config.load(CONFIG_FILE_PATH)
	
	if err != OK:
		# Default settings if config doesn't exist
		fullscreen_toggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		master_volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus)) * 100
	
		
		var current_size = DisplayServer.window_get_size()
		var closest_res_idx = 0
		var closest_dist = INF
		
		for i in range(resolutions.size()):
			var dist = abs(resolutions[i].x - current_size.x) + abs(resolutions[i].y - current_size.y)
			if dist < closest_dist:
				closest_dist = dist
				closest_res_idx = i
		
		resolution_dropdown.selected = closest_res_idx
		return
	
	# Load saved settings
	fullscreen_toggle.button_pressed = config.get_value("video", "fullscreen", false)
	master_volume_slider.value = config.get_value("audio", "master_volume", 100)
	
	var saved_res_idx = config.get_value("video", "resolution_index", 0)
	resolution_dropdown.selected = saved_res_idx

func save_settings():
	var config = ConfigFile.new()
	
	# Save video settings
	config.set_value("video", "fullscreen", fullscreen_toggle.button_pressed)
	config.set_value("video", "resolution_index", resolution_dropdown.selected)
	
	# Save audio settings
	config.set_value("audio", "master_volume", master_volume_slider.value)
	
	# Save to file
	config.save(CONFIG_FILE_PATH)

func apply_settings():
	# Apply video settings
	var fullscreen = fullscreen_toggle.button_pressed
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	# Apply resolution settings
	var selected_res = resolutions[resolution_dropdown.selected]
	if !fullscreen:
		DisplayServer.window_set_size(selected_res)
		# Center the window
		var screen_size = DisplayServer.screen_get_size()
		var window_pos = (screen_size - selected_res) / 2
		DisplayServer.window_set_position(window_pos)
	
	# Apply audio settings
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(master_volume_slider.value / 100))

func _on_apply_pressed():
	apply_settings()
	save_settings()

func _on_back_pressed():
	# Navigate back to main menu
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_fullscreen_toggled(toggled_on):
	# Optionally update immediately
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
