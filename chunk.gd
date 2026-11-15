extends CharacterBody2D
# A piece of the blob. Flies out when he's hit, slides to a stop,
# and gives the cell back when he touches it.

const FRICTION = 0.95
const PICKUP_DELAY = 0.4

var age = 0.0

func _ready():
	add_to_group("chunk")

func _physics_process(delta):
	age += delta
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal())
	velocity *= FRICTION
	if age >= PICKUP_DELAY:
		for body in $Pickup.get_overlapping_bodies():
			if body.is_in_group("player") and body.cells < body.max_cells:
				body.gain_cell()
				queue_free()
				return
