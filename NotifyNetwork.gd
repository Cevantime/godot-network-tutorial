extends Node

var timer_network
var nodes
var from_transforms = []
var target_transforms = []
var index_transform = 0

export(Array, NodePath) var nodes_to_notify
export(bool) var use_prediction = false

var waiting_nodes = []
var notifications_started = false
var old_transforms = []

func _ready():
	call_deferred("start_notifications")

func start_notifications():
	if get_tree().get_network_peer():
		timer_network = Timer.new()
		timer_network.wait_time = 0.2
		nodes = [get_parent()]
		for n in nodes_to_notify :
			var node = get_node(n)
			nodes.push_back(node)
		
		if is_network_master():
			if use_prediction:
				for n in (nodes + waiting_nodes):
					old_transforms.push_back(n.global_transform)
			add_child(timer_network)
			timer_network.start()
			timer_network.connect("timeout",self, "_notify_transform")
			
		else:
			for n in (nodes + waiting_nodes):
				from_transforms.push_back(n.global_transform)
				target_transforms.push_back(n.global_transform)
			
		notifications_started = true
		
func add_node_to_notify(node):
	if notifications_started:
		if node is NodePath:
			node = get_node(node)
		nodes.push_back(node)
		if is_network_master():
			if use_prediction:
				old_transforms.push_back(node.global_transform)
		else:
			from_transforms.push_back(node.global_transform)
			target_transforms.push_back(node.global_transform)
	else :
		if node is NodePath:
			nodes_to_notify.push_back(node)
		else:
			waiting_nodes.push_back(node)
		
func _process(_delta):
	interpolate_transforms()

func _notify_transform():
	if get_tree().get_network_peer() :
		var transforms = []
		if use_prediction:
			var i = 0
			for n in nodes:
				var old_t = old_transforms[i]
				var new_t = n.global_transform if (is_instance_valid(n) and n.is_inside_tree()) else Transform.IDENTITY
				old_transforms[i] = Transform(new_t) if new_t is Transform else Transform2D(new_t)
				new_t.origin += new_t.origin - old_t.origin
				transforms.push_back(new_t)
		else:
			for n in nodes:
				transforms.push_back(n.global_transform if (is_instance_valid(n) and n.is_inside_tree()) else Transform.IDENTITY)
		rpc("update_transforms", transforms)
	
puppet func update_transforms(transforms):
	from_transforms = target_transforms
	target_transforms = transforms
	index_transform = 0
	

func interpolate_transforms():
	if get_tree().get_network_peer() and not is_network_master():
		var i = 0
		index_transform += 1
		if nodes:
			for node in nodes:             
				if is_instance_valid(node):
					node.global_transform = from_transforms[i].interpolate_with(target_transforms[i], (1 / (timer_network.wait_time * Engine.get_frames_per_second())) * index_transform)
		#			node.global_transform = target_transforms[i]
				i += 1
