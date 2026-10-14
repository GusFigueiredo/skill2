extends Node

const PLAYER_ZOOM_SECONDS := 0.6
const PLAYER_HOLD_SECONDS := 0.6
const IARA_TRAVEL_SECONDS := 1.8
const IARA_HOLD_SECONDS := 0.6
const RETURN_SECONDS := 0.5
const END_HOLD_SECONDS := 0.5
const KISS_AUDIO_SECONDS := 0.88
const CLOSEUP_ZOOM_FACTOR := 1.4
const CUTSCENE_AUDIO := preload("res://soundeffect/Iara/Cutscene.mp3")

var fight: Node2D
var camera: Camera2D
var original_camera: Camera2D
var audio: AudioStreamPlayer
var letterbox: CanvasLayer
var sequence: Tween
var phase := "player"
var kiss_seconds := KISS_AUDIO_SECONDS
var laugh_seconds := 0.0
var finished := false
var boss_visual: AnimatedSprite2D
var player_visual: AnimatedSprite2D

func start(level: Node2D) -> void:
    fight = level
    fight.boss_intro_running = true
    fight.music.stop()
    if fight.chant != null:
        fight.chant.stop()
    fight.get_node("HUD").hide()
    fight.player.control_locked = true
    fight.player.set_physics_process(false)
    fight.player.velocity = Vector2.ZERO
    fight.player.facing = 1
    player_visual = fight.player.get_node("Sprite")
    player_visual.set_process(false)
    player_visual.flip_h = false
    player_visual.play("idle")
    boss_visual = fight.boss.get_node("Sprite")
    boss_visual.set_process(false)
    boss_visual.flip_h = false
    boss_visual.play("idle")

    audio = AudioStreamPlayer.new()
    audio.name = "IaraCutsceneAudio"
    audio.stream = CUTSCENE_AUDIO.duplicate()
    audio.stream.loop = false
    audio.volume_db = 0.0
    add_child(audio)
    kiss_seconds = minf(KISS_AUDIO_SECONDS, audio.stream.get_length() * 0.5)
    laugh_seconds = audio.stream.get_length() - kiss_seconds
    preload("res://scripts/IaraCutsceneFrames.gd").append_to(boss_visual.sprite_frames, kiss_seconds, laugh_seconds)

    original_camera = fight.player.get_node("Camera2D")
    original_camera.reset_smoothing()
    original_camera.force_update_scroll()
    camera = Camera2D.new()
    camera.name = "IaraIntroCamera"
    add_child(camera)
    camera.global_position = original_camera.get_screen_center_position()
    camera.zoom = original_camera.zoom
    camera.make_current()
    letterbox = preload("res://scripts/BossEntrance.gd").new()
    add_child(letterbox)

    var player_center: Vector2 = fight.player.global_position + fight.player.combat_bounds.get_center()
    var boss_center: Vector2 = fight.boss.global_position + fight.boss.combat_bounds.get_center()
    sequence = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    sequence.tween_property(camera, "global_position", player_center, PLAYER_ZOOM_SECONDS)
    sequence.parallel().tween_property(camera, "zoom", original_camera.zoom * CLOSEUP_ZOOM_FACTOR, PLAYER_ZOOM_SECONDS)
    sequence.tween_interval(PLAYER_HOLD_SECONDS)
    sequence.tween_callback(func(): phase = "iara")
    sequence.tween_property(camera, "global_position", boss_center, IARA_TRAVEL_SECONDS)
    sequence.tween_interval(IARA_HOLD_SECONDS)
    sequence.tween_callback(_begin_kiss)
    sequence.tween_method(_advance_kiss, 0.0, kiss_seconds, kiss_seconds).set_trans(Tween.TRANS_LINEAR)
    sequence.tween_callback(_begin_laugh)
    sequence.tween_method(_advance_laugh, 0.0, laugh_seconds, laugh_seconds).set_trans(Tween.TRANS_LINEAR)
    sequence.tween_callback(func(): phase = "hold")
    sequence.tween_interval(END_HOLD_SECONDS)
    sequence.tween_callback(func():
        phase = "return"
        boss_visual.play("idle")
    )
    sequence.tween_property(camera, "zoom", original_camera.zoom, RETURN_SECONDS)
    sequence.parallel().tween_property(camera, "global_position", original_camera.get_screen_center_position(), RETURN_SECONDS)
    sequence.tween_callback(finish)

func _begin_kiss() -> void:
    phase = "kiss"
    audio.play()
    boss_visual.play("intro_kiss")
    boss_visual.pause()

func _begin_laugh() -> void:
    phase = "laugh"
    boss_visual.play("intro_laugh")
    boss_visual.pause()

func _advance_kiss(elapsed: float) -> void:
    _set_pose("intro_kiss", elapsed, kiss_seconds)

func _advance_laugh(elapsed: float) -> void:
    _set_pose("intro_laugh", elapsed, laugh_seconds)

func _set_pose(animation_name: StringName, elapsed: float, duration: float) -> void:
    var count := boss_visual.sprite_frames.get_frame_count(animation_name)
    # Drive frames from the same clock as the audio window, including during tests.
    boss_visual.set_frame_and_progress(mini(count - 1, int(elapsed / maxf(duration, 0.001) * count)), 0.0)

func finish() -> void:
    _restore(true)

func abort() -> void:
    _restore(false)

func _restore(begin_fight: bool) -> void:
    if finished:
        return
    finished = true
    phase = "finished"
    if sequence != null and sequence.is_valid():
        sequence.kill()
    audio.stop()
    original_camera.make_current()
    original_camera.reset_smoothing()
    camera.queue_free()
    letterbox.queue_free()
    boss_visual.play("idle")
    boss_visual.set_process(true)
    player_visual.play("idle")
    player_visual.set_process(true)
    fight.player.control_locked = false
    fight.player.set_physics_process(begin_fight and fight.player.hp > 0)
    fight.boss_intro_running = false
    fight.get_node("HUD").show()
    if begin_fight:
        fight.state_timer = fight.INTRO_IDLE_SECONDS
        fight.music.volume_db = fight.original_music_volume
        fight.music.play_track(fight.BOSS_MUSIC_PATH)
    fight._update_hud()
