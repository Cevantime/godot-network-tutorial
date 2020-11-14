extends Area2D

export(float) var SPEED = 500.0

var player

func _ready():
	if is_network_master():
		connect("body_entered", self, "_on_Laser_body_entered")
		$VisibilityNotifier2D.connect("screen_exited", self, "_on_VisibilityNotifier2D_screen_exited")

func _process(delta):
	global_position += -transform.y * SPEED * delta


func _on_Laser_body_entered(body):	
	if body != player and body.has_method("get_damage"):
		body.rpc("get_damage")
		rpc("disappear")


func _on_VisibilityNotifier2D_screen_exited():
	rpc("disappear")

remotesync func disappear():
	queue_free()
