extends Node

var players: Dictionary = {}

func setup(sounds: Dictionary, volume_boosts_db: Dictionary = {}) -> void:
	for effect in sounds:
		var audio := AudioStreamPlayer.new()
		audio.name = effect
		var sound := load(sounds[effect]) as AudioStreamWAV
		if sound == null:
			push_error("Could not load sound effect: " + str(sounds[effect]))
			audio.free()
			continue
		audio.stream = sound.duplicate() as AudioStreamWAV
		audio.stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		audio.volume_db = -6.0 + float(volume_boosts_db.get(effect, 0.0))
		audio.max_polyphony = 4
		add_child(audio)
		players[effect] = audio

func play_effect(effect: String) -> void:
	if players.has(effect):
		players[effect].play()
