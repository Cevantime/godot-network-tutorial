extends Node

signal game_ready

const MAX_PLAYER_COUNT = 2
var is_server
var map_id_with_players = {}
var player_packed = preload("res://Player.tscn")
var player_ready_count = 0

func start_game(as_server = false):
	is_server = as_server
	var peer = NetworkedMultiplayerENet.new()
	
	if is_server:
		peer.create_server(54321, 3)
		create_player(1)
	else :
		peer.create_client("localhost", 54321)
		
	get_tree().network_peer = peer
	
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	get_tree().connect("connection_failed", self, "_on_connection_failed")
	get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_network_peer_disconnected")
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")
	

remote func create_player(id):
	var player = player_packed.instance()
	player.name = str(id)
	player.set_network_master(id)
	map_id_with_players[id] = player
	if get_tree().network_peer : 
		rpc_id(1, "new_player_added", map_id_with_players.size())
	
remotesync func new_player_added(player_count):
	if player_count == MAX_PLAYER_COUNT:
		player_ready_count += 1
		
	if player_ready_count == MAX_PLAYER_COUNT:
		rpc("emit_game_ready")
	
remotesync func emit_game_ready():
	emit_signal("game_ready")
	
func _on_connected_to_server():
	create_player(get_tree().get_network_unique_id())
	print("connected to server")
	
func _on_connection_failed():
	print("connection failed")
	
func _on_network_peer_connected(id):
	print("peer connected %s" % id)
	create_player(id)
	
func _on_network_peer_disconnected(id):
	print("peer connected %s" % id)
	
func _on_server_disconnected():
	print("server disconnected")
	get_tree().network_peer = null
