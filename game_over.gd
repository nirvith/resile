extends CanvasLayer
## Game over: shown after the blob runs out of respawns. The game is paused underneath.
## Space = bounce back (restart this level from wave 1). Esc = back to the title.

signal retry

func setup(level_number, times_down):
	$Card/Box/Detail.text = "Knocked down %d times on level %d." % [times_down, level_number]

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep working while the game is paused
	$Dim.modulate.a = 0.0
	$Card.modulate.a = 0.0
	$Card/Box/Stamp.scale = Vector2(2.5, 2.5)
	$Card/Box/Stamp.modulate.a = 0.0
	var t = create_tween()
	t.tween_property($Dim, "modulate:a", 1.0, 0.3)
	t.tween_property($Card, "modulate:a", 1.0, 0.3)
	t.tween_interval(0.25)
	# the red stamp slams down onto the report
	t.tween_property($Card/Box/Stamp, "modulate:a", 1.0, 0.05)
	t.parallel().tween_property($Card/Box/Stamp, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		retry.emit()
		queue_free()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		get_tree().paused = false
		Engine.time_scale = 1.0
		get_tree().change_scene_to_file("res://title.tscn")
