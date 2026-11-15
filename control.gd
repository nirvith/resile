extends Control

@onready var start_button: TextureButton = $TextureButton
@onready var tutorial_button: TextureButton = $tutorial

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	tutorial_button.pressed.connect(_on_tutorial_pressed)
	await get_tree().process_frame  # let the layout settle first
	button_jump()

func button_jump() -> void:
	var base_y := start_button.position.y
	var t := create_tween().set_loops()
	t.tween_property(start_button, "position:y", base_y - 6, 0.15) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(start_button, "position:y", base_y, 0.2) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.8)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://node_2d.tscn")

func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://tutorial.tscn")
