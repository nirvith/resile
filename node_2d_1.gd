extends CharacterBody2D
	
@export var speed: = 120.0
@export var max_health := 3
@export var contact_damage :=1
@export var attack_cooldown :=1.0

var health: int
var player: Node2D
var attack_timer: = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Area2D
@onready var health_bar: ProgressBar = $HealthBar


func _ready() -> void:
	health = max_health
	speed *= randf_range(0.8, 1.2)   # so a group spreads out instead of moving as one
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	print("Enemy found player: ", player)
	health_bar.max_value = max_health
	health_bar.value = health
	sprite.play()


func _physics_process(delta: float) -> void:
	# Godot calls this every physics tick (60/sec by default).
	# delta = seconds since the last tick (about 0.0167).
	if not is_instance_valid(player):
		return
	# Stop if there's no player or it has been freed (died). Without this,
	# using a deleted node crashes the game.

	var dir := global_position.direction_to(player.global_position)
	
	if get_slide_collision_count() > 0:
		var normal := get_slide_collision(0).get_normal()
		var around := Vector2(-normal.y, normal.x)
		if around.dot(dir) < 0:
			around = -around
		dir = (dir + around * 1.5).normalized()
	# Unit vector (length 1) pointing from the enemy to the player.
	# global_position = position in world space, not relative to the parent.
	velocity = dir * speed
	# velocity is a built-in CharacterBody2D property: direction × speed.
	move_and_slide()
	# Moves by velocity, handles collisions and slides along walls.
	# It applies delta itself, so you don't multiply by delta here.

	if abs(dir.x) > 0.1:
		sprite.flip_h = dir.x < 0
	# Mirror the sprite when the player is to the left. The 0.1 deadzone
	# stops flickering when the player is directly above or below.

	attack_timer -= delta
	# Count the cooldown down in real seconds.
	if attack_timer <= 0.0 and hitbox.overlaps_body(player):
		# Cooldown finished AND the player's body is inside the Hitbox area.
		attack_timer = attack_cooldown          # restart the cooldown
		if player.has_method("take_damage"):
			player.take_damage(contact_damage)
		# Duck typing, like Python: call it only if the player has it.
		# It works before your friend writes take_damage.

func take_damage(amount: int) -> void:
	# Public function; the player's weapon will call enemy.take_damage(1).
	health = maxi(health - amount, 0)
	health_bar.value = health
	if health <= 0:
		Sfx.hit_stop()
		get_tree().call_group("camera", "shake", 4)
		queue_free()
		# Delete this enemy at the end of the frame. Safer than deleting
		# immediately, which could crash code still using it this frame.
		return
	set_flash(1.0)
	# The alien shader (art/alien.gdshader) has a "flash" setting: 1 = red, 0 = normal green.
	create_tween().tween_method(set_flash, 1.0, 0.0, 0.15)
	# A tween animates a value over time: here the flash goes from red back
	# to green over 0.15s. It belongs to this node, so it stops if the enemy dies.


func set_flash(amount: float) -> void:
	# Each enemy has its own copy of the material (resource_local_to_scene),
	# so flashing one enemy doesn't flash all of them.
	sprite.material.set_shader_parameter("flash", amount)
