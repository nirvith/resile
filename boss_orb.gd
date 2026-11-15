extends CharacterBody2D
## A red boss shot. Bounces around the room and hurts the blob.
## Hit it with a live bolt and it turns gold and flies straight back into the boss.

const SPEED = 230.0
const RETURN_SPEED = 650.0
const MAX_BOUNCES = 4
const LIFETIME = 8.0
const RED = Color("ff3d5a")
const GOLD = Color("ffc93c")

var direction = Vector2.RIGHT
var boss
var bounces = 0
var returning = false
var life = LIFETIME

func _ready():
	add_to_group("enemies")    # player bolts only hit things in this group
	add_to_group("boss_orbs")
	$Sprite2D.modulate = RED

func launch(dir, from_boss):
	direction = dir
	boss = from_boss

func _physics_process(delta):
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	if returning:
		if not is_instance_valid(boss):
			queue_free()
			return
		direction = global_position.direction_to(boss.global_position)   # homes in, so it always lands
	var hit = move_and_collide(direction * (RETURN_SPEED if returning else SPEED) * delta)
	if hit == null:
		return
	var body = hit.get_collider()
	if returning:
		if body == boss:
			boss.take_damage(3)
			queue_free()
		else:
			add_collision_exception_with(body)   # passed through a crawler: ignore it
		return
	if body.is_in_group("player"):
		body.take_damage(1)
		queue_free()
		return
	direction = direction.bounce(hit.get_normal())
	bounces += 1
	if bounces > MAX_BOUNCES:
		queue_free()

# A live player bolt hit this orb: send it home.
func take_damage(_amount):
	if returning:
		return
	returning = true
	life = 3.0
	$Sprite2D.modulate = GOLD
	set_deferred("collision_mask", 4)   # now it only collides with enemies (the boss)
	get_tree().call_group("camera", "shake", 2)
