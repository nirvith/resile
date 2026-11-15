extends CanvasLayer
## A full-screen curtain used while level scenes swap.

@onready var curtain: ColorRect = $Curtain
var active_tween: Tween


func fade_to_black(duration: float = 0.42) -> void:
	curtain.show()
	await _fade_to(1.0, duration)


func fade_from_black(duration: float = 0.58) -> void:
	curtain.show()
	await _fade_to(0.0, duration)
	curtain.hide()


func _fade_to(alpha: float, duration: float) -> void:
	if active_tween and active_tween.is_running():
		active_tween.kill()
	active_tween = create_tween()
	active_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	active_tween.tween_property(curtain, "color:a", alpha, duration)
	await active_tween.finished
