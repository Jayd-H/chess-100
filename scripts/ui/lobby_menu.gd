extends Control

# Network constants
const DEFAULT_PORT = 28960
const MAX_PLAYERS = 2

# UI References
@onready var host_room_input = $VBoxContainer/HostSection/HostRoomContainer/HostRoomInput
@onready var status_label = $VBoxContainer/StatusContainer/StatusLabel
@onready var host_button = $VBoxContainer/HostSection/HostButton
@onready var join_button = $VBoxContainer/JoinSection/JoinButton
@onready var back_button = $VBoxContainer/BackButton
@onready var ip_input = $VBoxContainer/JoinSection/IPContainer/IPInput
@onready var join_room_input: LineEdit = $VBoxContainer/JoinSection/JoinRoomController/JoinRoomInput

# Network management
var peer = null
var room_name = ""
var player_info = {}
var my_info = { "status": "lobby", "army_data": null }

func _ready():
	# Connect button signals
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Connect network signals
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connected_to_server.connect(_connected_to_server)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.server_disconnected.connect(_server_disconnected)
	
	# Clear status
	status_label.text = ""

func _on_host_button_pressed():
	room_name = host_room_input.text.strip_edges()
	if room_name == "":
		status_label.text = "Please enter a room name"
		return
	
	# Create server
	peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	if result != OK:
		status_label.text = "Failed to create server"
		return
		
	multiplayer.multiplayer_peer = peer
	
	# Update UI
	status_label.text = "Hosting room: " + room_name + "\nWaiting for player..."
	host_button.disabled = true
	join_button.disabled = true

func _on_join_button_pressed():
	room_name = join_room_input.text.strip_edges()
	if room_name == "":
		status_label.text = "Please enter a room name"
		return
	
	var ip = ip_input.text.strip_edges()
	if ip == "":
		status_label.text = "Please enter an IP address"
		return
	
	# Connect to server
	peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(ip, DEFAULT_PORT)
	if result != OK:
		status_label.text = "Failed to connect"
		return
	
	multiplayer.multiplayer_peer = peer
	
	# Update UI
	status_label.text = "Connecting to room: " + room_name + "..."
	host_button.disabled = true
	join_button.disabled = true

func _player_connected(id):
	status_label.text = "Player connected! ID: " + str(id)
	
	# Send our info to the new player
	register_player.rpc_id(id, my_info)
	
	# If we're hosting, start army selection
	if multiplayer.is_server():
		status_label.text = "Player joined! Starting army selection..."
		await get_tree().create_timer(1.0).timeout
		
		# Tell client to start army selection too
		start_client_army_selection.rpc_id(id)
		
		# Then start our own army selection
		await get_tree().create_timer(0.5).timeout
		start_army_selection()

func _player_disconnected(id):
	status_label.text = "Player disconnected! ID: " + str(id)
	player_info.erase(id)
	
	# Return to lobby state
	host_button.disabled = false
	join_button.disabled = false

func _connected_to_server():
	status_label.text = "Connected to server!"
	
	# Register ourselves with the server
	register_player.rpc_id(1, my_info)

func _connection_failed():
	status_label.text = "Connection failed!"
	multiplayer.multiplayer_peer = null
	
	# Reset UI
	host_button.disabled = false
	join_button.disabled = false

func _server_disconnected():
	status_label.text = "Server disconnected!"
	multiplayer.multiplayer_peer = null
	
	# Reset UI
	host_button.disabled = false
	join_button.disabled = false

@rpc("any_peer")
func register_player(info):
	# Get the id of the RPC sender
	var id = multiplayer.get_remote_sender_id()
	
	# Store the info
	player_info[id] = info
	
	status_label.text = "Player registered! ID: " + str(id)
	
@rpc("authority", "call_remote")
func start_client_army_selection():
	status_label.text = "Host is ready! Starting army selection..."
	await get_tree().create_timer(0.5).timeout
	start_army_selection()

func start_army_selection():
	# This will be called when two players are connected
	# We'll transition to the army selection scene
	get_tree().change_scene_to_file("res://scenes/ui/single_unit_manager.tscn")

func _on_back_button_pressed():
	# Disconnect if connected
	if peer:
		peer.close()
	
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
