extends RigidBody2D

signal damaged(life)

export(float, 1.0, 500.0) var ANGULAR_ACCELERATION = 20
export(float, 0.5, 15.0) var LINEAR_ACCELERATION = 2.5

var laser_packed_scene = preload("res://Laser.tscn")
var index_transform = 0
var life = 10

onready var new_transform = global_transform
onready var old_transform = global_transform

func _ready():
	set_process(is_network_master())
	if is_network_master():
		$NotifyNetworkTimer.start()

func _process(_delta):
	if Input.is_action_pressed("ui_accept") and $ShootingTimer.is_stopped():
		rpc("start_shooting")
	elif Input.is_action_just_released("ui_accept") and not $ShootingTimer.is_stopped():
		rpc("stop_shooting")


func _integrate_forces(state):
	if is_network_master():
		var steering = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		var accelerate =  Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		
		state.apply_torque_impulse(steering * ANGULAR_ACCELERATION)
		state.apply_central_impulse(global_transform.y * accelerate * LINEAR_ACCELERATION)
		
		var pos = state.transform.origin

		var screen_size = get_viewport_rect().size
		
		pos.x = wrapf(pos.x, 0, screen_size.x)
		pos.y = wrapf(pos.y, 0, screen_size.y)

		state.transform.origin = pos
		
	else :
		state.transform = old_transform.interpolate_with(new_transform, index_transform / ($NotifyNetworkTimer.wait_time * Engine.get_frames_per_second()))
		index_transform += 1


remotesync func start_shooting():
	shoot()
	$ShootingTimer.start()
	
	
remotesync func stop_shooting():
	$ShootingTimer.stop()
	
	
remotesync func shoot():
	var laser = laser_packed_scene.instance()
	laser.player = self
	laser.set_network_master(int(name))
	laser.global_transform = global_transform
	get_tree().current_scene.add_child(laser)


func _on_TimerShooting_timeout():
	shoot()


func _on_NotifyNetworkTimer_timeout():
	rpc("_update_transform", global_transform, linear_velocity)


remote func _update_transform(_new_transform, _linear_velocity):
	if (old_transform.origin.distance_to(_new_transform.origin)) > 200.0:
		old_transform = _new_transform
		old_transform.origin -= _linear_velocity * $NotifyNetworkTimer.wait_time
	else:
		old_transform = global_transform
	
	new_transform = _new_transform
	index_transform = 0

func get_damage():
	life -= 1
	
	if life <= 0:
		queue_free()
		
	emit_signal("damaged", life)
