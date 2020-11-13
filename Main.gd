extends Node2D

var lifebar_packed_scene = preload("res://Lifebar.tscn")
var colors = [
	"blue",
	"green",
	"orange",
	"red"
]

func _on_ServerButton_pressed():
	create_game(true)

func _on_ClientButton_pressed():
	create_game()
	
func create_game(as_server = false):
	Lobby.start_game(as_server)
	
	$UILayer/JoinBox.hide()
	$UILayer/WaitingMsgNinePatch.show()
	
	yield(Lobby,"game_ready")
	
	$UILayer/WaitingMsgNinePatch.hide()
	
	var player_ids = Lobby.map_id_with_players.keys()
	
	player_ids.sort()
	
	var i = 0
	
	for id in player_ids:
		var player = Lobby.map_id_with_players[id]
		player.get_node("Sprite").texture = load("res://assets/png/playerShip1_%s.png" % colors[i])
		get_node("GameplayLayer/Players/PositionPlayer%s" % i).add_child(player)
		var lifebar = lifebar_packed_scene.instance()
		lifebar.texture_progress = load("res://assets/png/playerShip1_small_%s.png" % colors[i])
		lifebar.max_value = player.life
		player.connect("damaged", lifebar, "_on_player_damaged")
		$UILayer/LifebarBox.add_child(lifebar)
		i += 1


func _on_CreateGameButton_pressed():
	create_game(true)


func _on_JoinGameButton_pressed():
	create_game()
