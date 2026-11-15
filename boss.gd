extends CharacterBody2D
## A pinball themed boss whose incoming volleys can be bounced back at it.

enum Phase { RICOCHET, ROCK_BOTTOM, COMEBACK }
enum Attack { ROAM, WINDUP, RECOVER }

@export var max_health := 40
@export var move_speed := 48.0
@export var contact_damage := 1
@export var attack_cooldown := 2.35
@export var rock_bottom_at := 0.55
@export var recovered_cells := 5
@export var rock_bottom_max_time := 12.0
@export var minion_count := 3

const CRAWLER = preload("res://Crawler.tscn")
const ORB = preload("res://boss_orb.tscn")

var health: int
var player: Node2D
var phase := Phase.RICOCHET
var phase_time := 0.0
var attack := Attack.ROAM
var attack_timer := 1.4
var windup_timer := 0.0
var recovery_timer := 0.0
var contact_timer := 0.0
var volley_direction := Vector2.RIGHT
var invulnerable := false
var minions: Array[Node] = []
var grade: CanvasModulate
var grade_color := Color.WHITE
var say_tween: Tween

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = %HealthBar
@onready var line_label: Label = %Line


func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	add_to_group("bosses")
	sprite.play()
	health_bar.max_value = max_health
	health_bar.value = health
	line_label.modulate.a = 0.0
	grade = get_parent().get_node_or_null("ColourGrade") as CanvasModulate
	if grade:
		grade_color = grade.color
	say("FOREMAN: Shoot my red shots back at me. I dare you.")


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			return
	phase_time += delta
	attack_timer -= delta
	contact_timer = maxf(contact_timer - delta, 0.0)

	if phase == Phase.ROCK_BOTTOM:
		velocity = Vector2.ZERO
		if player.cells >= recovered_cells or phase_time >= rock_bottom_max_time:
			start_comeback()
		queue_redraw()
		return

	match attack:
		Attack.ROAM:
			var to_player := global_position.direction_to(player.global_position)
			velocity = to_player * (move_speed * (1.35 if phase == Phase.COMEBACK else 1.0))
			move_and_slide()
			if global_position.distance_to(player.global_position) < 92.0 and contact_timer <= 0.0:
				player.take_damage(contact_damage)
				contact_timer = 0.9
			if attack_timer <= 0.0:
				begin_volley()
		Attack.WINDUP:
			velocity = Vector2.ZERO
			windup_timer -= delta
			if windup_timer <= 0.0:
				fire_volley()
				attack = Attack.RECOVER
				recovery_timer = 0.82 if phase == Phase.RICOCHET else 0.62
				attack_timer = attack_cooldown if phase == Phase.RICOCHET else attack_cooldown * 0.9
		Attack.RECOVER:
			velocity = velocity.move_toward(Vector2.ZERO, 420.0 * delta)
			move_and_slide()
			recovery_timer -= delta
			if recovery_timer <= 0.0:
				attack = Attack.ROAM

	sprite.flip_h = velocity.x < 0.0 if absf(velocity.x) > 2.0 else sprite.flip_h
	queue_redraw()


func begin_volley() -> void:
	attack = Attack.WINDUP
	windup_timer = 0.92 if phase == Phase.RICOCHET else 0.72
	volley_direction = global_position.direction_to(player.global_position)
	velocity = Vector2.ZERO
	say("SHOTGUN SPREAD! SEND IT BACK!")
	get_tree().call_group("camera", "shake", 2)


func fire_volley() -> void:
	var radial_count := 12 if phase == Phase.RICOCHET else 18
	var radial_speed := 230.0 if phase == Phase.RICOCHET else 270.0
	var phase_offset := randf_range(0.0, TAU)
	for i in radial_count:
		var angle := phase_offset + TAU * float(i) / float(radial_count)
		spawn_orb(Vector2.RIGHT.rotated(angle), radial_speed)

	if phase == Phase.COMEBACK:
		# A short aimed fan follows the ring. Its gaps stay wide enough to read.
		var fan_count := 5
		var fan_spread := 0.68
		for i in fan_count:
			var offset := (float(i) / float(fan_count - 1) - 0.5) * fan_spread
			spawn_orb(volley_direction.rotated(offset), radial_speed * 0.9)
	get_tree().call_group("camera", "shake", 7 if phase == Phase.RICOCHET else 11)


func spawn_orb(direction: Vector2, orb_speed: float) -> void:
	var orb := ORB.instantiate() as Node2D
	get_parent().add_child(orb)
	orb.global_position = global_position
	orb.call("launch", direction, orb_speed)


func take_damage(amount: int) -> void:
	if invulnerable or health <= 0:
		return
	health = maxi(health - amount, 0)
	health_bar.value = health
	if health <= 0:
		die()
		return
	set_flash(1.0)
	create_tween().tween_method(set_flash, 1.0, 0.0, 0.16)
	if phase == Phase.RICOCHET and health <= max_health * rock_bottom_at:
		start_rock_bottom()


func start_rock_bottom() -> void:
	phase = Phase.ROCK_BOTTOM
	phase_time = 0.0
	attack = Attack.ROAM
	attack_timer = 999.0
	invulnerable = true
	velocity = Vector2.ZERO
	clear_projectiles()
	if is_instance_valid(player):
		player.shatter(1)
	dim_screen(true)
	say("ROCK BOTTOM! Grab your cells and bounce back!")
	get_tree().call_group("camera", "shake", 18)
	for i in minion_count:
		var crawler := CRAWLER.instantiate() as Node2D
		var angle := TAU * float(i) / float(minion_count)
		crawler.global_position = global_position + Vector2.RIGHT.rotated(angle) * 180.0
		get_parent().add_child.call_deferred(crawler)
		minions.append(crawler)


func start_comeback() -> void:
	phase = Phase.COMEBACK
	phase_time = 0.0
	invulnerable = false
	attack = Attack.ROAM
	attack_timer = 1.0
	for minion in minions:
		if is_instance_valid(minion):
			minion.queue_free()
	minions.clear()
	clear_projectiles()
	dim_screen(false)
	say("FOREMAN: You bounced back? Then catch this!")
	velocity = Vector2.RIGHT.rotated(randf() * TAU) * move_speed * 1.5
	get_tree().call_group("camera", "shake", 12)


func clear_projectiles() -> void:
	for orb in get_tree().get_nodes_in_group("boss_projectiles"):
		if is_instance_valid(orb):
			orb.queue_free()


func die() -> void:
	clear_projectiles()
	for minion in minions:
		if is_instance_valid(minion):
			minion.queue_free()
	Sfx.hit_stop()
	get_tree().call_group("camera", "shake", 24)
	queue_free()


func set_flash(amount: float) -> void:
	sprite.material.set_shader_parameter("flash", amount)


func dim_screen(on: bool) -> void:
	if grade == null:
		return
	var target := grade_color.darkened(0.62) if on else grade_color
	create_tween().tween_property(grade, "color", target, 0.55)


func say(text: String) -> void:
	if say_tween:
		say_tween.kill()
	line_label.text = text
	line_label.modulate.a = 1.0
	say_tween = create_tween()
	say_tween.tween_interval(2.1)
	say_tween.tween_property(line_label, "modulate:a", 0.0, 0.5)


func _draw() -> void:
	if attack == Attack.WINDUP:
		var progress := 1.0 - clampf(windup_timer / (0.92 if phase == Phase.RICOCHET else 0.72), 0.0, 1.0)
		var color := Color(1.0, 0.32, 0.18, 0.85) if phase == Phase.RICOCHET else Color(1.0, 0.78, 0.2, 0.9)
		draw_arc(Vector2.ZERO, 62.0 + progress * 94.0, 0.0, TAU, 72, color, 7.0, true)
		if phase == Phase.COMEBACK:
			var aim_end := volley_direction * 210.0
			draw_line(Vector2.ZERO, aim_end, Color(1.0, 0.7, 0.2, 0.55), 5.0, true)
	elif phase == Phase.ROCK_BOTTOM:
		draw_arc(Vector2.ZERO, 112.0, 0.0, TAU, 64, Color(0.25, 0.82, 1.0, 0.35), 4.0, true)


func _exit_tree() -> void:
	if grade and is_instance_valid(grade):
		grade.color = grade_color
