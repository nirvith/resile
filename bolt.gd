extends CharacterBody2D

const Speed = 600.0
const Max_bounces = 3

var direction = Vector2.RIGHT
var bounces = 0
var live = false

func _ready():
	modulate.a = 0.4
	
func _physics_process(delta):
	var collision = move_and_collide(direction * Speed * delta)
	if not collision:
		return
	var hit = collision.getcollider()
	
	if hit.is_in_group("enemies"):
		if live:
			var landed = true
			if hit.has_method("hit_by_bolt"):
				landed = hit.hit_by_bolt(1, global_position - direction *20)
			else:
				hit.take_damage(1)
			if landed:
				queue_free()
				return
			set_collision_mask_value(2, true)
		direction = direction.bounce(collision.get_normal())
		return
		
		if hit.is_in_group("player"):
			if hit.has_method("take_damage"):
				hit.take_damage(1)
			queue_free()
			return
		if bounces >= Max_bounces:
			queue_free()
			return
		direction = direction.bounces(collision.get_normal())
		bounces += 1
		if not live:
			live = true
			modulate.a = 1.0	
	
	#if collision:
	#	if bounces >= Max_bounces:
	#		queue_free()
	#		return
	#	direction = direction.bounce(collision.get_normal())
	#	bounces += 1
	#	if not live:
	#		live = true
	#		modulate.a = 1.0

 
