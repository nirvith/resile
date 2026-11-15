extends CharacterBody2D
## Red boss shots ricochet around the room; a player bolt turns one gold and sends it home.

const MAX_LIFE := 6.0
const MAX_BOUNCES := 5
const REFLECTED_SPEED := 650.0

var direction := Vector2.RIGHT
var speed := 220.0
var life_left := MAX_LIFE
var bounces := 0
var reflected := false
var boss: Node2D

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss_projectiles")
	$Hitbox.body_entered.connect(_on_hitbox_body_entered)


func launch(initial_direction: Vector2, initial_speed: float) -> void:
	direction = initial_direction.normalized()
	speed = initial_speed


func _physics_process(delta: float) -> void:
	life_left -= delta
	if life_left <= 0.0:
		queue_free()
		return
	sprite.rotation += delta * (5.0 if reflected else 2.2)
	var collision := move_and_collide(direction * speed * delta)
	if collision == null:
		return
	var body := collision.get_collider()
	if reflected and body.is_in_group("bosses"):
		body.take_damage(2)
		get_tree().call_group("camera", "shake", 5)
		queue_free()
		return
	if not reflected and body.is_in_group("player"):
		body.take_damage(1)
		queue_free()
		return
	direction = direction.bounce(collision.get_normal()).normalized()
	bounces += 1
	if bounces >= MAX_BOUNCES:
		queue_free()


func take_damage(_amount: int) -> void:
	if reflected:
		return
	reflected = true
	collision_mask = 4
	life_left = 4.0
	speed = REFLECTED_SPEED
	var target := get_tree().get_first_node_in_group("bosses") as Node2D
	if is_instance_valid(target):
		boss = target
		direction = global_position.direction_to(target.global_position)
	else:
		direction = -direction
	sprite.modulate = Color("fff0aa")
	$Hitbox.set_deferred("monitoring", false)
	get_tree().call_group("camera", "shake", 2)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not reflected:
		body.take_damage(1)
		queue_free()
