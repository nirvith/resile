extends Node2D


const GAME = "res://comicStrip.tscn"
const TUTORIAL = "res://tutorial.tscn"
const BOLT_SPEED = 420.0
const TRAIL_POINTS = 22
const ROOM = Rect2(16, 56, 1120, 576)

var bolt_dir = Vector2(1, -1.2).normalized()

func _ready():
	blob_hop()
	drop_title()
	blink_prompt()

func _process(delta):
	move_bolt(delta)

func move_bolt(delta):
	var orb = $Front/Orb
	orb.position += bolt_dir * BOLT_SPEED * delta
	var bounced = false
	if orb.position.x < ROOM.position.x or orb.position.x > ROOM.end.x:
		bolt_dir.x = -bolt_dir.x
		bounced = true
	if orb.position.y < ROOM.position.y or orb.position.y > ROOM.end.y:
		bolt_dir.y = -bolt_dir.y
		bounced = true
	orb.position = orb.position.clamp(ROOM.position, ROOM.end)
	$Front/Trail.add_point(orb.position)
	if $Front/Trail.get_point_count() > TRAIL_POINTS:
		$Front/Trail.remove_point(0)


func blob_hop():
	var ground = $Blob.position.y
	var t = create_tween().set_loops()
	t.tween_property($Blob, "scale", Vector2(3.5, 2.5), 0.08)
	t.tween_property($Blob, "scale", Vector2(2.7, 3.3), 0.08)
	t.parallel().tween_property($Blob, "position:y", ground - 50, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property($Blob, "scale", Vector2(3, 3), 0.1)
	t.tween_property($Blob, "position:y", ground, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func drop_title():
	var letters = $Front/Title.get_children()
	for i in letters.size():
		var letter = letters[i]
		var final_y = letter.position.y
		letter.position.y = -200
		var t = create_tween()
		t.tween_interval(0.3 + i * 0.12)
		t.tween_property(letter, "position:y", final_y, 0.9).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func blink_prompt():
	var t = create_tween().set_loops()
	t.tween_interval(0.55)
	t.tween_callback(func(): $Front/Prompt.visible = not $Front/Prompt.visible)

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		get_tree().change_scene_to_file(GAME)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_H:
		get_tree().change_scene_to_file(TUTORIAL)
