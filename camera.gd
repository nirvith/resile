extends Camera2D
# Follows the blob, stays inside the room, and can shake.
# Anything can shake it with: get_tree().call_group("camera", "shake", 8)

const ZOOM_LEVEL = 1.15

var strength = 0.0
var target

func _ready():
	add_to_group("camera")
	target = get_tree().get_first_node_in_group("player")
	zoom = Vector2(ZOOM_LEVEL, ZOOM_LEVEL)
	limit_left = 0
	limit_top = 0
	limit_right = 1152
	limit_bottom = 648
	position_smoothing_enabled = true
	position_smoothing_speed = 6.0

func _process(delta):
	if is_instance_valid(target):
		global_position = target.global_position
	offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength
	strength = move_toward(strength, 0, 40 * delta)

func shake(amount):
	strength = max(strength, amount)
