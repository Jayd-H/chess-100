extends Node

# Network constants
const DEFAULT_PORT = 28960
const MAX_PLAYERS = 2

# Connection states
enum ConnectionState {
	DISCONNECTED,
	CONNECTING,
	CONNECTED_AS_HOST,
	CONNECTED_AS_CLIENT
}

# Game states
enum GameState {
	LOBBY,
	ARMY_SELECTION,
	GAME_READY,
	PLAYING,
	GAME_OVER
}

# Network variables
var multiplayer_peer = null
var connection_state = ConnectionState.DISCONNECTED
var game_state = GameState.LOBBY
var room_name = ""
var player_info = {}
var my_info = {
	"name": "Player",
	"status": "lobby",
	"army_data": null,
	"is_white": false
}
var opponent_id = 0

# Signals
signal connection_established()
signal connection_failed()
signal player_connected(id)
signal player_disconnected(id)
signal army_received(army_data)
signal move_received(from_pos, to_pos)
signal game_started(is_white)
signal checkmate_received()

func _ready():
	print("NetworkManager initializing...")
	# Set random seed based on time
	randomize()
	
	# Connect to signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	print("NetworkManager ready, signals connected")

# HOST FUNCTIONS
func create_server(room):
	if connection_state != ConnectionState.DISCONNECTED:
		return false
	
	room_name = room
	multiplayer_peer = ENetMultiplayerPeer.new()
	var result = multiplayer_peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	
	if result != OK:
		print("Failed to create server")
		emit_signal("connection_failed")
		return false
	
	multiplayer.multiplayer_peer = multiplayer_peer
	connection_state = ConnectionState.CONNECTED_AS_HOST
	
	# Server is ALWAYS ID 1
	print("*** SERVER ID = 1, FORCING WHITE COLOR ***")
	my_info.is_white = true
	
	my_info.status = "host"
	
	print("Server created with ID: " + str(multiplayer.get_unique_id()))
	print("Server created for room: " + room_name)
	print("I AM WHITE (host) - GUARANTEED BY ID")
	return true

# CLIENT FUNCTIONS
func connect_to_server(ip, room):
	if connection_state != ConnectionState.DISCONNECTED:
		return false
	
	room_name = room
	multiplayer_peer = ENetMultiplayerPeer.new()
	
	connection_state = ConnectionState.CONNECTING
	var result = multiplayer_peer.create_client(ip, DEFAULT_PORT)
	
	if result != OK:
		print("Failed to create client")
		connection_state = ConnectionState.DISCONNECTED
		emit_signal("connection_failed")
		return false
	
	multiplayer.multiplayer_peer = multiplayer_peer
	connection_state = ConnectionState.CONNECTED_AS_CLIENT
	
	# Non-server players ALWAYS have IDs > 1 in Godot networking
	print("*** CLIENT ID > 1, FORCING BLACK COLOR ***")
	my_info.is_white = false
	
	my_info.status = "client"
	
	# Setup client signals
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	print("Connecting to server at " + ip + " for room: " + room_name)
	print("Client connected with ID: " + str(multiplayer.get_unique_id()))
	print("I AM BLACK (client) - GUARANTEED BY ID")
	return true

# GAME STATE FUNCTIONS
func submit_army(army_data):
	# FORCE COLOR BASED ON ID BEFORE SUBMISSION
	set_color_by_id()
	
	my_info.army_data = army_data
	my_info.status = "army_ready"
	
	print("COLOR VERIFICATION: I am " + ("WHITE" if my_info.is_white else "BLACK"))
	
	# Send updated info to opponent
	if opponent_id != 0:
		update_player_info.rpc_id(opponent_id, my_info)
		
	# Check if we can start the game
	check_game_start()

# Helper function to set color definitively by ID
func set_color_by_id():
	var my_id = multiplayer.get_unique_id()
	
	# ID == 1 means server/host, which is WHITE
	# Any other ID means client, which is BLACK
	if my_id == 1:
		if !my_info.is_white:
			print("*** FIXING COLOR: ID=1 MUST BE WHITE ***")
			my_info.is_white = true
	else:
		if my_info.is_white:
			print("*** FIXING COLOR: ID>1 MUST BE BLACK ***")
			my_info.is_white = false
	
	print("ID-BASED COLOR CHECK: ID=" + str(my_id) + ", I am " + ("WHITE" if my_info.is_white else "BLACK"))

func send_move(from_pos, to_pos):
	if opponent_id != 0:
		send_move_to_opponent.rpc_id(opponent_id, from_pos, to_pos)

func send_checkmate():
	if opponent_id != 0:
		send_checkmate_to_opponent.rpc()
		game_state = GameState.GAME_OVER

func disconnect_from_game():
	if multiplayer_peer:
		multiplayer_peer.close()
	
	# Reset state
	connection_state = ConnectionState.DISCONNECTED
	game_state = GameState.LOBBY
	opponent_id = 0
	player_info.clear()
	my_info.army_data = null
	my_info.status = "lobby"
	# Color will be set again when reconnecting

# INTERNAL FUNCTIONS
func _on_peer_connected(id):
	print("Player connected with id: " + str(id))
	
	# Store opponent ID
	opponent_id = id
	
	# Force color by ID first
	set_color_by_id()
	
	# Print color verification
	print("COLOR CHECK: I am " + ("WHITE" if my_info.is_white else "BLACK"))
	
	# Send our info to the new player
	update_player_info.rpc_id(id, my_info)
	
	emit_signal("player_connected", id)

func _on_peer_disconnected(id):
	print("Player disconnected with id: " + str(id))
	
	if id == opponent_id:
		opponent_id = 0
		player_info.erase(id)
	
	emit_signal("player_disconnected", id)

func _on_connected_to_server():
	print("Connected to server")
	
	# If we know the server's ID, store it
	if multiplayer.has_multiplayer_peer() and multiplayer.get_unique_id() != 1:
		opponent_id = 1
	
	# Force color by ID
	set_color_by_id()
	
	# Print color verification
	print("COLOR CHECK AFTER SERVER CONNECTION: I am " + ("WHITE" if my_info.is_white else "BLACK"))
	
	# Send our info to the server
	update_player_info.rpc_id(1, my_info)
	
	emit_signal("connection_established")

func _on_connection_failed():
	print("Connection failed")
	connection_state = ConnectionState.DISCONNECTED
	emit_signal("connection_failed")

func _on_server_disconnected():
	print("Server disconnected")
	connection_state = ConnectionState.DISCONNECTED
	emit_signal("connection_failed")

@rpc("any_peer")
func update_player_info(info):
	var id = multiplayer.get_remote_sender_id()
	
	print("Received player info update from " + str(id))
	print("- Info contains army? " + str(info.army_data != null))
	
	# Enforce correct color based on ID for the received info
	var corrected_info = info.duplicate()
	corrected_info.is_white = (id == 1)  # ID 1 is white, others are black
	
	print("- Player SHOULD BE " + ("WHITE" if corrected_info.is_white else "BLACK") + " (by ID)")
	
	# Store the corrected player info
	player_info[id] = corrected_info
	
	# Force our own color again
	set_color_by_id()
	
	# Check if we can start the game 
	print("Checking if game can start after receiving player info...")
	var can_start = await check_game_start()
	print("- Game can start? " + str(can_start))
	
	# If the opponent has submitted their army and we're waiting
	if info.army_data != null and my_info.army_data == null:
		# Signal that we received the opponent's army
		emit_signal("army_received", info.army_data)

@rpc("any_peer")
func send_move_to_opponent(from_pos, to_pos):
	print("Received move: " + str(from_pos) + " -> " + str(to_pos))
	emit_signal("move_received", from_pos, to_pos)

@rpc("any_peer")
func send_checkmate_to_opponent():
	print("Received checkmate!")
	game_state = GameState.GAME_OVER
	emit_signal("checkmate_received")

func check_game_start():
	# ENFORCE COLOR BY ID
	set_color_by_id()
	
	print("Checking game start conditions...")
	print("- My army ready: " + str(my_info.army_data != null))
	print("- My color (white?): " + str(my_info.is_white))
	print("- Game state: " + str(game_state))
	print("- My opponent ID: " + str(opponent_id))
	
	if opponent_id != 0:
		var opponent_info = player_info.get(opponent_id, null)
		if opponent_info != null:
			# FORCE OPPONENT COLOR BY ID
			var opponent_should_be_white = (opponent_id == 1)
			if opponent_info.is_white != opponent_should_be_white:
				print("Fixing opponent color: " + str(opponent_id) + " should be " + 
					  ("WHITE" if opponent_should_be_white else "BLACK"))
				opponent_info.is_white = opponent_should_be_white
				player_info[opponent_id] = opponent_info
				
			print("- Opponent army ready: " + str(opponent_info.army_data != null))
			print("- Opponent color (white?): " + str(opponent_info.is_white))
		else:
			print("ERROR: No opponent info available for ID: " + str(opponent_id))
			return false
			
		# Only start the game if both players have submitted armies
		if my_info.army_data != null and opponent_info and opponent_info.army_data != null:
			print("BOTH PLAYERS READY! Starting game!")
			
			# FINAL COLOR CHECK BEFORE GAME STARTS
			set_color_by_id()
			
			# Set game state
			game_state = GameState.GAME_READY
			
			print("Final color assignment - I am: " + ("WHITE" if my_info.is_white else "BLACK"))
			
			# Wait a brief moment for RPC messages to process
			await get_tree().create_timer(0.2).timeout
			
			# Emit signal to start the game
			print("EMITTING GAME_STARTED SIGNAL!")
			game_started.emit(my_info.is_white)
			return true
		else:
			var waiting_for = ""
			if my_info.army_data == null:
				waiting_for += "my army"
			if opponent_info.army_data == null:
				if waiting_for != "":
					waiting_for += " and "
				waiting_for += "opponent's army"
			print("Still waiting for " + waiting_for)
	else:
		print("No opponent connected!")
		
	return false

# Public helper function to get player color (100% reliable)
func am_i_white():
	# ALWAYS base color on player ID - most reliable way
	var my_id = multiplayer.get_unique_id()
	return my_id == 1
