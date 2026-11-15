extends Node

const ENEMIES = {
	"crawler": preload("res://Crawler.tscn"),
	"glutton": preload("res://Glutton.tscn"),
}
const Message_box = "res://message_box.tscn"
const ending = "res://ending.tscn"
const Room_center = Vector2(576, 324)
const SPAWN_GAP = 0.3   # seconds between each enemy appearing

var waves = [
	{"line" : "You're still getting fired, by the way.", "enemies" : {"crawler": 3}},
	{"line" : "That's definitely coming out of your last pay check", "enemies" : {"crawler": 5}},
	{"line" : "Huh. You're still alive?", "enemies" : {"crawler": 5, "glutton": 2}},
	{"line" : "It's over. Nobody gets back up from something like that", "enemies" : {"crawler": 6, "glutton": 2}},
	{"line" : "Okay, Please save my ship. I'll give you a raise.", "enemies" : {"crawler": 7, "glutton": 3}},
]

var current = 0
var running = false
var player
var wave_id = 0   # changes whenever a wave starts or resets, so an old spawn loop knows to stop


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
	wave_id += 1
	var my_id = wave_id
	if with_line:
		await say(waves[current].line)
		if my_id != wave_id:
			return
	# Build the list of enemies for this wave, shuffled, then spawn them one by one.
	var to_spawn = []
	var wave_enemies = waves[current].enemies
	for enemy_name in wave_enemies:
		for i in wave_enemies[enemy_name]:
			to_spawn.append(enemy_name)
	to_spawn.shuffle()
	for enemy_name in to_spawn:
		spawn_enemy(enemy_name)
		await get_tree().create_timer(SPAWN_GAP).timeout
		if my_id != wave_id:
			return
	running = true

func spawn_enemy(enemy_name):
	var enemy = ENEMIES[enemy_name].instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = spawn_point()

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
	var points = get_tree().get_nodes_in_group("enemy_spawn")
	if points.is_empty():
		return Vector2(randf_range(100, 1052), randf_range(100, 548))
	points.shuffle()
	for marker in points:
		if marker.global_position.distance_to(player.global_position) > 250:
			return marker.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	return points[0].global_position

func _on_player_died():
	running = false
	wave_id += 1
	for group in ["enemies", "bolts", "chunk"]:
		for node in get_tree().get_nodes_in_group(group):
			node.queue_free()
	player.cells = player.max_cells
	player.update_look()
	player.global_position = Room_center
	player.invulnerable_left = 1.5
	start_wave.call_deferred(false)

func finish_game():
	if ResourceLoader.exists(ending):
		get_tree().change_scene_to_file(ending)
	else:
		print("Game finished: no ending.tscn yet")
