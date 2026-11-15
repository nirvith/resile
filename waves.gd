extends Node

const ENEMIES = {
	"crawler": preload("res://Crawler.tscn"),
	"glutton": preload("res://Glutton.tscn"),
	"boss": preload("res://boss.tscn"),
}

const Message_box = "res://message_box.tscn"
const ending = "res://ending.tscn"
const SPAWN_GAP = 0.3   # seconds between each enemy appearing

var levels = [
	{"map": "res://cargo_hold.tscn", "waves": [
		{"line": "You're still getting fired, by the way.", "enemies": {"crawler": 3}},
		{"line": "That's definitely coming out of your last pay check", "enemies": {"crawler": 5}},
		{"line": "Huh. You're still alive?", "enemies": {"crawler": 5, "glutton": 2}},
	]},
	{"map": "res://control_deck.tscn", "waves": [
		{"line": "Why are you in my office? Don't touch anything.", "enemies": {"crawler": 6, "glutton": 2}},
		{"line": "Those floors are imported. Stop bouncing on them.", "enemies": {"crawler": 7, "glutton": 3}},
		{"line": "Stop. Seriously. You're scratching everything.", "enemies": {"crawler": 8, "glutton": 4}},
	]},
	{"map": "res://boss_arena.tscn", "waves": [
		{"line": "Fine. I'm sending the Foreman.", "enemies": {"boss": 1}},
	]},
]

var level = 0
var current = 0
var map

func load_level():
	for group in ["enemies", "bolts", "chunk"]:
		for node in get_tree().get_nodes_in_group(group):
			node.queue_free()
	if map:
		map.get_parent().remove_child(map)
		map.queue_free()
	map = load(levels[level].map).instantiate()
	get_parent().add_child(map)
	get_parent().move_child(map, 0)
	get_parent().get_node("ColourGrade").color = map.get_meta("tint", Color.WHITE)
	player.global_position = map.get_node("Spawn").global_position
	player.cells = player.max_cells
	player.update_look()
	
	
func next_level():
	level += 1
	if level >= levels.size():
		finish_game()
		return
	current = 0
	var transition = get_parent().get_node_or_null("SceneTransition")
	if transition:
		await transition.fade_to_black(0.42)
	load_level()
	await get_tree().process_frame
	if transition:
		await transition.fade_from_black(0.58)
	start_wave(true)

var running = false
var player
var wave_id = 0   # changes whenever a wave starts or resets, so an old spawn loop knows to stop


func _ready():
	player = get_tree().get_first_node_in_group("player")
	player.died.connect(_on_player_died)
	load_level.call_deferred()
	start_wave.call_deferred(true)

func wave():
	return levels[level].waves[current]

func _physics_process(_delta):
	if running and get_tree().get_nodes_in_group("enemies").is_empty():
		running = false
		current += 1
		if current >= levels[level].waves.size():
			next_level()
		else:
			start_wave(true)

func start_wave(with_line):
	wave_id += 1
	var my_id = wave_id
	if with_line:
		await say(wave().line)
		if my_id != wave_id:
			return
	# Build the list of enemies for this wave, shuffled, then spawn them one by one.
	var to_spawn = []
	var wave_enemies = wave().enemies
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
	if enemy_name == "boss" and map and map.has_node("Spawn"):
		enemy.global_position = map.get_node("Spawn").global_position + Vector2(210, 0)
	else:
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
	player.global_position = map.get_node("Spawn").global_position
	player.invulnerable_left = 1.5
	start_wave.call_deferred(false)

func finish_game():
	if ResourceLoader.exists(ending):
		get_tree().change_scene_to_file(ending)
	else:
		print("Game finished: no ending.tscn yet")
