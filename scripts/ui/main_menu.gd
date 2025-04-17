extends Control

func _ready():
	$VBoxContainer/PlayButton.pressed.connect(_on_Play_pressed)
	$VBoxContainer/UnitManagerButton.pressed.connect(_on_UnitManager_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_Quit_pressed)
	$SettingsButton.pressed.connect(_on_settings_button_pressed)
	$VBoxContainer/MultiplayerButton.pressed.connect(_on_multiplayer_button_pressed)

func _on_Play_pressed():
	# Change to Army Selector scene
	get_tree().change_scene_to_file("res://scenes/ui/army_selector.tscn")

func _on_UnitManager_pressed():
	# Change to Unit Manager scene
	get_tree().change_scene_to_file("res://scenes/ui/unit_manager.tscn")
	
func _on_Quit_pressed():
	# Exit the game
	get_tree().quit()

func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/settings_menu.tscn")

func _on_multiplayer_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/lobby_menu.tscn")
