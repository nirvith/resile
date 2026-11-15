extends CharacterBody2D
## THE FOREMAN, the level 3 boss.
## FIGHT: walks at you, glows red, then fires a ring of red orbs. Hit an orb with a
##        live bolt and it turns gold and flies back into him.
## ROCK BOTTOM (at half health): you're shattered to 1 cell, he shields up and sends
##        crawlers. Collect your cells to bounce back.
## COMEBACK: faster, bigger rings plus an aimed fan. Finish him.

enum State { FIGHT, ROCK_BOTTOM, COMEBACK }

const ORB = preload("res://boss_orb.tscn")
const CRAWLER = preload("res://Crawler.tscn")
const MESSAGE_BOX = preload("res://message_box.tscn")

const MAX_HEALTH = 30
const SPEED = 55.0
const VOLLEY_GAP = 3.0        # seconds between volleys
const WINDUP = 0.8            # red warning glow before each volley
const TOUCH_RANGE = 95.0      # how close counts as touching the blob
const RECOVER_CELLS = 5       # rock bottom ends when you're back to this many cells...
const ROCK_BOTTOM_MAX = 12.0  # ...or after this many seconds
const ORB_START = 30.0        # orbs start near his centre, so they never spawn inside a wall
const SAFE_TIME = 2.0         # seconds of safety for the blob right after the shatter
const MINIONS = 2             # crawlers sent in during rock bottom
const GREY = Color(0.72, 0.72, 0.78)   # rock bottom wash: grey, not dark

var health = MAX_HEALTH
var state = State.FIGHT
var player
var volley_timer = 2.0
var windup_left = 0.0
var touch_cooldown = 0.0
var rock_time = 0.0
var minions = []
var grade
var grade_color = Color.WHITE
var radio_box
var rock_started = false   # true once the shatter has actually happened

func _ready():
	add_to_group("enemies")
	add_to_group("bosses")
	player = get_tree().get_first_node_in_group("player")
	grade = get_parent().get_node_or_null("ColourGrade")
	if grade:
		grade_color = grade.color
	$Sprite.play()
	$BossUI/HealthBar.max_value = MAX_HEALTH
	$BossUI/HealthBar.value = health
	radio.call_deferred("That's the Foreman. He's never missed a day of work in his life.")

func _physics_process(delta):
	if not is_instance_valid(player):
		return
	touch_cooldown -= delta
	if state == State.ROCK_BOTTOM:
		if not rock_started:   # the shatter runs a moment later (deferred); don't judge recovery before it
			return
		rock_time += delta
		if player.cells >= RECOVER_CELLS or rock_time >= ROCK_BOTTOM_MAX:
			start_comeback()
		queue_redraw()
		return
	if windup_left > 0.0:
		windup_left -= delta
		set_flash(1.0 - windup_left / WINDUP)   # glows redder and redder: the warning
		if windup_left <= 0.0:
			fire_volley()
		queue_redraw()
		return
	var dir = global_position.direction_to(player.global_position)
	velocity = dir * SPEED * (1.4 if state == State.COMEBACK else 1.0)
	move_and_slide()
	if abs(dir.x) > 0.1:
		$Sprite.flip_h = dir.x < 0
	if touch_cooldown <= 0.0 and global_position.distance_to(player.global_position) < TOUCH_RANGE:
		player.take_damage(1)
		touch_cooldown = 1.0
	volley_timer -= delta
	if volley_timer <= 0.0:
		windup_left = WINDUP
		volley_timer = VOLLEY_GAP * (0.8 if state == State.COMEBACK else 1.0)
	queue_redraw()

func fire_volley():
	set_flash(0.0)
	var count = 10 if state == State.FIGHT else 14
	var turn = randf() * TAU
	for i in count:
		spawn_orb(Vector2.RIGHT.rotated(turn + TAU * i / count))
	if state == State.COMEBACK:
		var aim = global_position.direction_to(player.global_position)
		for i in 5:
			spawn_orb(aim.rotated((i - 2) * 0.18))
	get_tree().call_group("camera", "shake", 6)

func spawn_orb(dir):
	var orb = ORB.instantiate()
	get_parent().add_child(orb)
	orb.global_position = global_position + dir * ORB_START
	orb.launch(dir, self)

# Called by live player bolts (1) and returned gold orbs (3).
func take_damage(amount):
	if state == State.ROCK_BOTTOM or health <= 0:
		return
	health -= amount
	$BossUI/HealthBar.value = health
	if health <= 0:
		die()
		return
	if windup_left <= 0.0:
		set_flash(1.0)
		create_tween().tween_method(set_flash, 1.0, 0.0, 0.15)
	if state == State.FIGHT and health <= MAX_HEALTH / 2:
		state = State.ROCK_BOTTOM          # set now so it can't trigger twice
		start_rock_bottom.call_deferred()  # deferred: this can run inside a physics callback

func start_rock_bottom():
	rock_started = true
	rock_time = 0.0
	windup_left = 0.0
	set_flash(0.0)
	velocity = Vector2.ZERO
	clear_orbs()
	# Refill first, so there are always 7 pieces to collect, however hurt you were.
	player.cells = player.max_cells
	player.shatter(1)
	player.invulnerable_left = SAFE_TIME
	dim(true)
	show_banner()
	radio("It's over. Nobody gets back up from something like that.", 3.5)
	# Crawlers come in on the far side of the room from the blob, not on top of him.
	var away = player.global_position.direction_to(global_position)
	for i in MINIONS:
		var crawler = CRAWLER.instantiate()
		var spot = global_position + away.rotated((i - 0.5) * 1.2) * 150.0
		crawler.position = spot.clamp(Vector2(80, 100), Vector2(1072, 580))   # never inside a wall
		get_parent().add_child(crawler)
		minions.append(crawler)

func start_comeback():
	state = State.COMEBACK
	for minion in minions:
		if is_instance_valid(minion):
			minion.queue_free()
	minions.clear()
	dim(false)
	volley_timer = 1.0
	radio("...Wait. You're getting back up?", 3.0)
	get_tree().call_group("camera", "shake", 10)

func die():
	clear_orbs()
	for minion in minions:
		if is_instance_valid(minion):
			minion.queue_free()
	Sfx.hit_stop(0.12)
	get_tree().call_group("camera", "shake", 20)
	queue_free()

func clear_orbs():
	for orb in get_tree().get_nodes_in_group("boss_orbs"):
		orb.queue_free()

func set_flash(amount):
	$Sprite.material.set_shader_parameter("flash", amount)

func dim(on):
	if grade:
		var target = grade_color.lerp(GREY, 0.7) if on else grade_color
		create_tween().tween_property(grade, "color", target, 0.5)

# "ROCK BOTTOM / GRAB YOUR PIECES" in the middle of the screen, then it fades away.
func show_banner():
	var banner = $BossUI/Banner
	banner.modulate.a = 1.0
	banner.show()
	var t = create_tween()
	t.tween_interval(2.0)
	t.tween_property(banner, "modulate:a", 0.0, 0.6)
	t.tween_callback(banner.hide)

# The boss on the radio: the same message box as between waves, but it closes itself.
func radio(text, seconds = 3.0):
	if is_instance_valid(radio_box):
		radio_box.queue_free()
	radio_box = MESSAGE_BOX.instantiate()
	get_parent().add_child(radio_box)
	radio_box.show_line(text, seconds)
	radio_box.finished.connect(radio_box.queue_free)

func _draw():
	if state == State.ROCK_BOTTOM:
		draw_arc(Vector2.ZERO, 105.0, 0.0, TAU, 64, Color(0.31, 0.84, 0.9, 0.6), 5.0)   # shield
	elif windup_left > 0.0:
		var grow = 1.0 - windup_left / WINDUP
		draw_arc(Vector2.ZERO, 70.0 + grow * 80.0, 0.0, TAU, 64, Color(1.0, 0.24, 0.35, 0.8), 6.0)

func _exit_tree():
	if is_instance_valid(radio_box):
		radio_box.queue_free()
	if grade and is_instance_valid(grade):
		grade.color = grade_color
