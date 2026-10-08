extends Node

var forest: AudioStreamPlayer
var crackle: AudioStreamPlayer
var active := false
var ducked := false

func _ready() -> void:
    forest = _loop("forest", -23.0)
    crackle = _loop("crackle", -26.0)

func _loop(sound: String, volume: float) -> AudioStreamPlayer:
    var audio := AudioStreamPlayer.new()
    audio.stream = load("res://soundeffect/Feedback/%s.wav" % sound).duplicate()
    audio.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    audio.stream.loop_begin = 0
    audio.stream.loop_end = roundi(audio.stream.get_length() * audio.stream.mix_rate)
    audio.volume_db = volume
    add_child(audio)
    return audio

func begin() -> void:
    active = true
    ducked = false
    for audio in [forest, crackle]:
        audio.volume_db = -60
        audio.play()

func duck() -> void:
    ducked = true

func end() -> void:
    active = false

func _process(delta: float) -> void:
    var level = get_parent()
    if level.finished or level.player.hp <= 0:
        active = false
    for audio in [forest, crackle]:
        var target := -60.0
        if active:
            target = (-35.0 if ducked else -23.0) if audio == forest else (-38.0 if ducked else -26.0)
        audio.volume_db = move_toward(audio.volume_db, target, delta * 48.0)
        if not active and audio.volume_db <= -59.9:
            audio.stop()
