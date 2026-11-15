extends CharacterBody2D

const Max_bounces = 3
const PIERCE_AFTER = 2          # after this many bounces, bolts go through enemies
const SPEED_UP = 1.15           # each bounce: 15% faster and bigger
const MAX_SPEED = 1500.0        # cap, so the bolt never becomes impossible to follow
const PINBALL_BOOST = 1.6       # one-off speed jump when a bolt hits a pinball pad
const PINBALL_BOUNCES = 10      # bounces a pinball bolt gets
const CYAN = Color("4fd6e6")          # palette: faint bolt = still "yours", harmless
const GOLD = Color("ffc93c")          # palette: live bolt = power
const PINBALL_COLOR = Color("fff0aa") # palette: hot gold = maximum power
const MAX_ORB_SCALE = 3.0             # the orb stops growing at twice its starting size
const BOUNCE_SOUND = preload("res://sounds/bounce.wav")
const HIT_SOUND = preload("res://sounds/hit.wav")
const PINBALL_SOUND = preload("res://sounds/pinball.wav")

var speed = 600.0
var direction = Vector2.RIGHT
var bounces = 0
var max_bounces = Max_bounces
var live = false
var pinball = false
var trail   # Line2D drawn behind a pinball bolt; stays empty for normal bolts

func _ready():
	add_to_group("bolts")
	$Sprite2D.modulate = CYAN
	modulate.a = 0.5

func _physics_process(delta):
	var collision = move_and_collide(direction * speed * delta)
	if trail:
		trail.add_point(global_position)
		if trail.get_point_count() > 14:
			trail.remove_point(0)
	if collision:
		var hit = collision.get_collider()
		if hit.is_in_group("pinball_pad") and not pinball:
			start_pinball(hit)
		elif bounces >= max_bounces:
			queue_free()
			return
		direction = direction.bounce(collision.get_normal())
		bounces += 1
		speed = min(speed * SPEED_UP, MAX_SPEED)
		if $Sprite2D.scale.x < MAX_ORB_SCALE:
			$Sprite2D.scale *= SPEED_UP
		# pitch rises with each bounce, so you can hear the bolt charging up
		Sfx.play(BOUNCE_SOUND, -8.0, 1.0 + min(bounces, 8) * 0.12)
		if not live:
			live = true
			modulate.a = 1.0
			$Sprite2D.modulate = GOLD

func start_pinball(pad):
	pinball = true
	live = true
	bounces = 0
	max_bounces = PINBALL_BOUNCES
	speed = min(speed * PINBALL_BOOST, MAX_SPEED)
	$Sprite2D.modulate = PINBALL_COLOR
	pad.flash()
	Sfx.play(PINBALL_SOUND, -2.0, 1.0)
	get_tree().call_group("camera", "shake", 3)
	trail = Line2D.new()
	trail.top_level = true
	trail.width = 6.0
	trail.default_color = Color(GOLD, 0.5)
	add_child(trail)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if not live:
		return
	if body.is_in_group("enemies"):
		Sfx.play(HIT_SOUND, -2.0)
		body.take_damage(1)
		if bounces < PIERCE_AFTER and not pinball:
			queue_free()
	elif body.is_in_group("player") and not pinball:
		body.take_damage(1)
