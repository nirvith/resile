extends Node


const Crawler = preload("res://Crawler.tscn")
const Message_box = "res://message_box.tscn"
const ending = "res://ending.tscn"
const Room_center = Vector2(576, 324)

var waves = [
	{"line" : "You're still getting fired, by the way.", "crawlers" : 3},
	{"line" : "That's definitely coming out of your last pay check", "crawlers" : 5},
	{"line" : "Huh. You're still alive?", "crawlers": 7},
	{"line" : "It's over. Nobody gets back up from something like that", "crawlers" : 8},
	{"line" : "Okay, Please save my ship. I'll give you a raise.", "crawlers" : 10}
]

var current = 0
var running = false
var player


func _ready():
	player = get_tree().get_first_node_in_group("player")
	player.died.connect(_on_player_died)
	start_wave.call_deferred(true)
	
func _physics_process(_delta):
	if running and get_tree().get_nodes_in_group("enemies").is_empty():
		running = false
		current += 1
		if current >= waves.size():
			finish_game()
		else:
			start_wave(true)
		
func start_wave(with_line):
	if with_line:
		await say(waves[current].line)
		
	for i in waves[current].crawlers:
		var crawler = Crawler.instantiate()
		get_parent().add_child(crawler)
		crawler.global_position = spawn_point()
	running = true

func say(text):
	if ResourceLoader.exists(Message_box):
		var box = load(Message_box).instantiate()
		add_child(box)
		box.show_line(text)
		await box.finished
		box.queue_free()
	else:
		print("Boss: ", text)
		await get_tree().create_timer(1.5).timeout

func spawn_point():
	var point = Room_center
	for attempt in 20:
		point = Vector2(randf_range(60, 1092), randf_range(60, 588))
		if point.distance_to(player.global_position) > 250:
			break
	return point

func _on_player_died():
	running = false
	
	for node in get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("bolts"):
		node.queue_free()
	player.cells = player.max_cells
	player.update_look()
	player.global_position = Room_center
	player.invulnerable_left = 1.0
	start_wave.call_deferred(false)
		
func finish_game():
	if ResourceLoader.exists(ending):
		get_tree().change_scene_to_file(ending)
	else:
		print("Game finished: no ending.tscn yet")
