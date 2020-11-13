extends TextureProgress


func _on_player_damaged(life):
	value = life
	if life < 0:
		hide()
	
