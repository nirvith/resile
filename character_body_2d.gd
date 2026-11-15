extends CharacterBody2D
signal died

const Bolt = preload("res://bolt.tscn")
const Chunk = preload("res://chunk.tscn")
const SHOOT_SOUND = preload("res://sounds/shoot.wav")
const HURT_SOUND = preload("res://sounds/hurt.wav")
const PICKUP_SOUND = preload("res://sounds/pickup.wav")
const fire_rate_cooldown = .35
const max_bolts = 3
const max_cells = 8
const invulnerable_time = 0.5
const throw_speed = 400
const ALARM_RED = Color("ff3d5a")   # palette red = damage


var speed = 200
var cooldown_left = 0.0
var cells = max_cells
var invulnerable_left = 0.0


func _ready() -> void:
	$Sprite.play()
	update_look()

func _physics_process(delta):
	cooldown_left -= delta
	invulnerable_left -= delta
	$Sprite.modulate.a = 0.5 if invulnerable_left > 0 else 1.0
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = speed * direction
	move_and_slide()

func _unhandled_input(event):
	if event.is_action_pressed("shoot") and cooldown_left <= 0 and get_tree().get_nodes_in_group("bolts").size() < max_bolts:
		cooldown_left = fire_rate_cooldown
		var bolt = Bolt.instantiate()
		get_parent().add_child(bolt)
		bolt.global_position = global_position
		bolt.direction = (get_global_mouse_position() - global_position).normalized()
		Sfx.play(SHOOT_SOUND, -4.0)


func take_damage(amount):
	if invulnerable_left > 0:
		return
	amount = min(amount, cells)
	cells -= amount
	for i in amount:
		throw_chunk.call_deferred()
	Sfx.play(HURT_SOUND)
	get_tree().call_group("camera", "shake", 8)
	# Red hurt flash. self_modulate is separate from modulate, so it doesn't
	# fight with the invulnerability blink, which changes modulate's alpha.
	$Sprite.self_modulate = ALARM_RED
	create_tween().tween_property($Sprite, "self_modulate", Color.WHITE, 0.25)
	invulnerable_left = invulnerable_time
	update_look()
	if cells <= 0:
		died.emit()

func gain_cell():
	cells = min(cells + 1, max_cells)
	Sfx.play(PICKUP_SOUND, -4.0)
	update_look()

func throw_chunk(chunk_speed = throw_speed):
	var chunk = Chunk.instantiate()
	get_parent().add_child(chunk)
	chunk.global_position = global_position
	chunk.velocity = Vector2.RIGHT.rotated(randf() * TAU) * chunk_speed

# For rock bottom: drop to `keep` cells and fling the rest hard across the room.
func shatter(keep):
	var lost = cells - keep
	cells = keep
	for i in lost:
		throw_chunk.call_deferred(900)
	get_tree().call_group("camera", "shake", 20)
	update_look()

func update_look():
	$Sprite.scale = Vector2.ONE * lerp(0.6, 1.0, (cells - 1) / 7.0)
	$CellLabel.text = str(cells)
