extends Area2D

export(float) var SPEED = 500.0

var player

func _process(delta):
	global_position += -transform.y * SPEED * delta


func _on_Laser_body_entered(body):
	if body != player and body.has_method("get_damage"):
		body.get_damage()
		queue_free()


func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
