extends CanvasLayer
## The boss's radio. Types a line out letter by letter.
## Between waves (close_after = 0): Space skips the typing, then Space closes it.
## During the boss fight (close_after > 0): closes by itself, so the fight never pauses.

signal finished

const TYPE_SPEED = 45.0   # letters per second

var typing = false
var shown = 0.0
var done = false
var close_after = 0.0

func show_line(text, auto_close = 0.0):
	$Panel/Text.text = text
	$Panel/Text.visible_characters = 0
	$Panel/Hint.visible = false
	shown = 0.0
	typing = true
	done = false
	close_after = auto_close

func _process(delta):
	if typing:
		shown += TYPE_SPEED * delta
		$Panel/Text.visible_characters = int(shown)
		if shown >= $Panel/Text.text.length():
			finish_typing()
	elif close_after > 0.0 and not done:
		close_after -= delta
		if close_after <= 0.0:
			close()

func finish_typing():
	typing = false
	$Panel/Text.visible_characters = -1
	$Panel/Hint.visible = close_after <= 0.0   # only show "SPACE" when Space is needed

func close():
	done = true
	finished.emit()

func _unhandled_input(event):
	if done or close_after > 0.0 or not event.is_action_pressed("ui_accept"):
		return
	get_viewport().set_input_as_handled()
	if typing:
		finish_typing()
	else:
		close()
