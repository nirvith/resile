extends Node
# Global helper (autoload "Sfx"): any script can call Sfx.play(...) or Sfx.hit_stop().

func play(stream, volume_db = 0.0, pitch = 0.0):
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	# pitch 0 means "slightly random", so repeated sounds don't feel robotic
	player.pitch_scale = pitch if pitch > 0.0 else randf_range(0.9, 1.1)
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func hit_stop(duration = 0.05):
	# Freeze the game for a split second so kills feel heavy.
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
