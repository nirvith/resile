extends CharacterBody2D

const Max_bounces = 3
const PIERCE_AFTER = 2          # after this many bounces, bolts go through enemies
const SPEED_UP = 1.15           # each bounce: 15% faster and bigger
const BOUNCE_SOUND = preload("res://sounds/bounce.wav")
const HIT_SOUND = preload("res://sounds/hit.wav")

var speed = 600.0
var direction = Vector2.RIGHT
var bounces = 0
var live = false

func _ready():
	add_to_group("bolts")
	modulate.a = 0.4

func _physics_process(delta):
	var collision = move_and_collide(direction * speed * delta)
	if collision:
		if bounces >= Max_bounces:
			queue_free()
			return
		direction = direction.bounce(collision.get_normal())
		bounces += 1
		speed *= SPEED_UP
		$Sprite2D.scale *= SPEED_UP
		# pitch rises with each bounce, so you can hear the bolt charging up
		Sfx.play(BOUNCE_SOUND, -8.0, 1.0 + bounces * 0.15)
		if not live:
			live = true
			modulate.a = 1.0

func _on_hitbox_body_entered(body: Node2D) -> void:
	if not live:
		return
	if body.is_in_group("enemies"):
		Sfx.play(HIT_SOUND, -2.0)
		body.take_damage(1)
		if bounces < PIERCE_AFTER:
			queue_free()
	elif body.is_in_group("player"):
		body.take_damage(1)
