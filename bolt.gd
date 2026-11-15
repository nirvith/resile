extends CharacterBody2D

const Speed = 600.0
const Max_bounces = 3

var direction = Vector2.RIGHT
var bounces = 0
var live = false

func _ready():
	add_to_group("bolts")
	modulate.a = 0.4
	
func _physics_process(delta):
	var collision = move_and_collide(direction * Speed * delta)
	if collision:
		if bounces >= Max_bounces:
			queue_free()
			return
		direction = direction.bounce(collision.get_normal())
		bounces += 1
		if not live:
			live = true
			modulate.a = 1.0

 


func _on_hitbox_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
