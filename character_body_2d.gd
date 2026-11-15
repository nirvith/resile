extends CharacterBody2D

const Bolt = preload("res://bolt.tscn")
const fire_rate_cooldown = .35
const max_bolts = 3


var speed = 200
var cooldown_left = 0.0

func _ready() -> void:
	$Sprite.play()
	
func _physics_process(delta):
	cooldown_left -= delta
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
		


func take_damage(amount):
	print("lost ", amount, " cell(s)")

func gain_cell():
	print("gained a cell")
	
	
