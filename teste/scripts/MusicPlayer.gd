extends AudioStreamPlayer

func _init() -> void:
	name = "MusicPlayer"
	volume_db = -10.0

func play_track(path: String) -> void:
	var track := load(path) as AudioStreamMP3
	if track == null:
		push_error("Could not load music: " + path)
		return
	stop()
	stream = track.duplicate() as AudioStreamMP3
	stream.loop = true
	play()
