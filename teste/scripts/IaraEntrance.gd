extends Node

const PLAYER_ZOOM_SECONDS := 0.6
const PLAYER_HOLD_SECONDS := 0.6
const IARA_TRAVEL_SECONDS := 1.8
const IARA_HOLD_SECONDS := 0.6
const RETURN_SECONDS := 0.5
const END_HOLD_SECONDS := 0.5
const KISS_AUDIO_SECONDS := 0.88
const CLOSEUP_ZOOM_FACTOR := 1.4
const PLAYER_HOLD_ZOOM_FACTOR := 1.44
const IARA_ARRIVAL_ZOOM_FACTOR := 1.46
const IARA_VOICE_ZOOM_FACTOR := 1.48
const IARA_FINAL_ZOOM_FACTOR := 1.62
const PLAYER_LOOK_ROOM := Vector2(24, -2)
const IARA_LOOK_ROOM := Vector2(-32, -3)
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
var player_focus := Vector2.ZERO
var boss_focus := Vector2.ZERO
var player_center := Vector2.ZERO
var boss_center := Vector2.ZERO
var glimmer: KissGlimmer

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
    camera.limit_top = original_camera.limit_top
    camera.limit_bottom = original_camera.limit_bottom
    camera.make_current()
    letterbox = preload("res://scripts/BossEntrance.gd").new()
    letterbox.cool_theme = true
    add_child(letterbox)

    player_center = fight.player.global_position + fight.player.combat_bounds.get_center()
    boss_center = fight.boss.global_position + fight.boss.combat_bounds.get_center()
    # Leave room in front of each face, so the two shots share an eyeline.
    player_focus = _focus_point(player_center + PLAYER_LOOK_ROOM, original_camera.zoom * CLOSEUP_ZOOM_FACTOR)
    boss_focus = _focus_point(boss_center + IARA_LOOK_ROOM, original_camera.zoom * IARA_ARRIVAL_ZOOM_FACTOR)
    glimmer = KissGlimmer.new()
    glimmer.character_height = fight.boss.combat_bounds.size.y
    glimmer.z_index = 20
    add_child(glimmer)
    glimmer.global_position = boss_center
    sequence = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    sequence.tween_property(camera, "global_position", player_focus, PLAYER_ZOOM_SECONDS)
    sequence.parallel().tween_property(camera, "zoom", original_camera.zoom * CLOSEUP_ZOOM_FACTOR, PLAYER_ZOOM_SECONDS)
    sequence.tween_method(_hold_player, 0.0, 1.0, PLAYER_HOLD_SECONDS)
    sequence.tween_callback(func(): phase = "iara")
    sequence.tween_method(_travel_to_iara, 0.0, 1.0, IARA_TRAVEL_SECONDS)
    sequence.tween_callback(func(): letterbox.set_title("IARA", "ENCANTO DO RIO NEGRO"))
    sequence.tween_method(_hold_iara, 0.0, 1.0, IARA_HOLD_SECONDS)
    sequence.tween_callback(_begin_kiss)
    sequence.tween_method(_advance_kiss, 0.0, kiss_seconds, kiss_seconds).set_trans(Tween.TRANS_LINEAR)
    sequence.tween_callback(_begin_laugh)
    sequence.tween_method(_advance_laugh, 0.0, laugh_seconds, laugh_seconds).set_trans(Tween.TRANS_LINEAR)
    sequence.tween_callback(func(): phase = "hold")
    sequence.tween_interval(END_HOLD_SECONDS)
    sequence.tween_callback(func():
        phase = "return"
        boss_visual.play("idle")
        letterbox.dismiss(RETURN_SECONDS)
    )
    sequence.tween_property(camera, "zoom", original_camera.zoom, RETURN_SECONDS)
    sequence.parallel().tween_property(camera, "global_position", original_camera.get_screen_center_position(), RETURN_SECONDS)
    sequence.tween_callback(finish)

func _focus_point(world_center: Vector2, zoom: Vector2) -> Vector2:
    var half_view := get_viewport().get_visible_rect().size.y / (zoom.y * 2.0)
    world_center.y = clampf(world_center.y, original_camera.limit_top + half_view, original_camera.limit_bottom - half_view)
    return world_center

func _hold_player(progress: float) -> void:
    camera.zoom = original_camera.zoom * lerpf(CLOSEUP_ZOOM_FACTOR, PLAYER_HOLD_ZOOM_FACTOR, progress)
    camera.global_position = _focus_point(player_center + PLAYER_LOOK_ROOM, camera.zoom)

func _travel_to_iara(progress: float) -> void:
    # Breathe out during the pan, then gently move closer as Iara comes into view.
    var zoom_factor := lerpf(PLAYER_HOLD_ZOOM_FACTOR, IARA_ARRIVAL_ZOOM_FACTOR, progress) - sin(PI * progress) * 0.12
    camera.zoom = original_camera.zoom * zoom_factor
    var focus := (player_center + PLAYER_LOOK_ROOM).lerp(boss_center + IARA_LOOK_ROOM, progress)
    camera.global_position = _focus_point(focus + Vector2(0, -sin(PI * progress) * 10.0), camera.zoom)

func _hold_iara(progress: float) -> void:
    camera.zoom = original_camera.zoom * lerpf(IARA_ARRIVAL_ZOOM_FACTOR, IARA_VOICE_ZOOM_FACTOR, progress)
    camera.global_position = _focus_point(boss_center + IARA_LOOK_ROOM, camera.zoom)

func _voice_closeup(elapsed: float) -> void:
    # One slow movement spans both gestures, without a camera cut at the laugh.
    var progress := smoothstep(0.0, kiss_seconds + laugh_seconds, elapsed)
    camera.zoom = original_camera.zoom * lerpf(IARA_VOICE_ZOOM_FACTOR, IARA_FINAL_ZOOM_FACTOR, progress)
    camera.global_position = _focus_point(boss_center + IARA_LOOK_ROOM + Vector2(8, -5) * progress, camera.zoom)

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
    _voice_closeup(elapsed)
    var progress := elapsed / maxf(kiss_seconds, 0.001)
    glimmer.clock = elapsed
    glimmer.strength = sin(PI * progress) * 0.45 + progress * 0.35
    glimmer.queue_redraw()
    letterbox.accent_strength = glimmer.strength

func _advance_laugh(elapsed: float) -> void:
    _set_pose("intro_laugh", elapsed, laugh_seconds)
    _voice_closeup(kiss_seconds + elapsed)
    var progress := elapsed / maxf(laugh_seconds, 0.001)
    glimmer.clock = kiss_seconds + elapsed
    glimmer.strength = (1.0 - smoothstep(0.0, 0.6, progress)) * 0.35
    glimmer.queue_redraw()
    letterbox.accent_strength = glimmer.strength

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
    glimmer.queue_free()
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

class KissGlimmer extends Node2D:
    var clock := 0.0
    var strength := 0.0
    var character_height := 100.0

    func _draw() -> void:
        if strength <= 0.001:
            return
        var source := Vector2(-12, -character_height * 0.29)
        for i in range(18):
            # Each fleck leaves her hand once, then floats toward the player.
            var age := clock - (0.26 + float(i) * 0.027)
            if age < 0.0 or age > 1.7:
                continue
            var progress := age / 1.7
            var point := source + Vector2(-progress * (90.0 + i * 2.0), sin(progress * TAU + i * 0.8) * 6.0 - progress * 16.0)
            var alpha := smoothstep(0.0, 0.15, progress) * (1.0 - smoothstep(0.55, 1.0, progress)) * strength
            draw_circle(point, 5.0, Color(0.26, 0.78, 0.85, alpha * 0.08))
            draw_circle(point, 1.15, Color(0.71, 0.96, 1.0, alpha * 0.82))
            if i % 4 == 0:
                var radius := 2.0 + sin(progress * PI) * 1.2
                draw_line(point - Vector2(radius, 0), point + Vector2(radius, 0), Color(0.70, 0.96, 1.0, alpha * 0.55), 0.7, true)
                draw_line(point - Vector2(0, radius), point + Vector2(0, radius), Color(0.70, 0.96, 1.0, alpha * 0.55), 0.7, true)
