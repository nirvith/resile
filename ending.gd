extends Control
## The ending comic. Space (or Enter) goes back to the title screen.

func _ready():
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.8)   # fade in

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://title.tscn")
