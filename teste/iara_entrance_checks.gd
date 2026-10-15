extends SceneTree

const Progress = preload("res://scripts/CampaignProgress.gd")
const CUTSCENE_PATH := "res://soundeffect/Iara/Cutscene.mp3"
const SPELL_PATH := "res://soundeffect/Iara/Preprando e soltando ataque.mp3"
const HIT_PATH := "res://soundeffect/Iara/hit.mp3"
const MUSIC_PATH := "res://music/Iara.mp3"

var failures := 0

class SoundProbe extends RefCounted:
    var plays := 0

    func play() -> void:
        plays += 1

func _initialize() -> void:
    call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error(message)

func same_mp3(stream: AudioStream, path: String) -> bool:
    var expected := load(path) as AudioStreamMP3
    return stream is AudioStreamMP3 and expected != null and stream.data == expected.data

func advance_to(sequence: Tween, elapsed: float) -> void:
    sequence.custom_step(maxf(0.0, elapsed - sequence.get_total_elapsed_time()))

func run_checks() -> void:
    create_timer(20.0, true).timeout.connect(func():
        push_error("Iara introduction checks timed out")
        quit(1)
    )
    for index in range(3):
        Progress.complete_stage(index)
    change_scene_to_file("res://rio_negro4.tscn")
    await process_frame
    await process_frame
    var fight = current_scene
    preload("res://iara_test_support.gd").reach_boss(fight)
    var entrance = fight.entrance
    var hero = fight.player
    var visual: AnimatedSprite2D = fight.boss.get_node("Sprite")
    var gameplay_camera: Camera2D = hero.get_node("Camera2D")
    fight.set_process(false)
    fight.set_physics_process(false)
    entrance.sequence.pause()

    check(fight.boss_intro_running and entrance.phase == "player", "Iara's introduction must open on the player")
    check(hero.control_locked and not hero.is_physics_processing(), "The introduction must lock movement, attacks and rolling")
    check(not fight.music.playing, "Battle music must wait until the introduction ends")
    check(not fight.chant.playing, "The distant chant must also stop during the cutscene")
    check(not entrance.audio.playing, "Iara's voice must wait until her close-up")
    var idle_time: float = fight.state_timer
    var elapsed: float = fight.fight_elapsed
    var hero_position: Vector2 = hero.position
    var hero_hp: int = hero.hp
    Input.action_press("ui_right")
    hero._physics_process(0.25)
    hero._attack()
    hero._start_dodge(1)
    Input.action_release("ui_right")
    fight._physics_process(8.0)
    check(hero.position == hero_position and not hero.is_dodging and hero.attack_cooldown_timer == 0, "No player action may run during the introduction")
    check(fight.state == fight.State.IDLE and fight.state_timer == idle_time and fight.fight_elapsed == elapsed, "The boss clock and opening idle must stay frozen")
    check(not is_instance_valid(hero.seduction_source) and fight.minions.is_empty(), "The introduction must not start a charm or spawn enemies")
    hero.take_damage(1)
    check(hero.hp == hero_hp, "The player must be protected during the introduction")
    fight.state = fight.State.VULNERABLE
    fight.boss.take_damage(1)
    check(fight.boss.hp == fight.boss.max_hp, "Iara must be protected during her introduction")
    fight.state = fight.State.IDLE

    advance_to(entrance.sequence, entrance.PLAYER_ZOOM_SECONDS)
    check(entrance.camera.zoom.x > gameplay_camera.zoom.x, "The camera must first zoom in on the player")
    check(absf(entrance.camera.global_position.x - hero.global_position.x) < 50.0, "The first close-up must frame the player")
    var player_closeup_zoom: Vector2 = entrance.camera.zoom
    var travel_start: float = entrance.PLAYER_ZOOM_SECONDS + entrance.PLAYER_HOLD_SECONDS
    advance_to(entrance.sequence, travel_start + 0.002)
    check(entrance.camera.zoom.x > player_closeup_zoom.x, "The player's shot must keep moving gently during its hold")
    var travel_departure_zoom: Vector2 = entrance.camera.zoom
    advance_to(entrance.sequence, travel_start + entrance.IARA_TRAVEL_SECONDS * 0.5)
    check(entrance.camera.zoom.x < travel_departure_zoom.x, "The pan must widen briefly to show the river between both actors")
    check(entrance.camera.global_position.x > hero.global_position.x and entrance.camera.global_position.x < fight.boss.global_position.x, "The camera must travel through the scenery between both close-ups")
    var iara_arrival: float = entrance.PLAYER_ZOOM_SECONDS + entrance.PLAYER_HOLD_SECONDS + entrance.IARA_TRAVEL_SECONDS
    advance_to(entrance.sequence, iara_arrival + 0.002)
    check(absf(entrance.camera.global_position.x - fight.boss.global_position.x) < 50.0, "The camera must then travel to Iara")
    check(not entrance.audio.playing, "The travel to Iara must precede her voice")
    var kiss_start: float = iara_arrival + entrance.IARA_HOLD_SECONDS
    advance_to(entrance.sequence, kiss_start + 0.002)
    check(entrance.phase == "kiss" and visual.animation == "intro_kiss", "Iara must blow a kiss before laughing")
    check(not visual.is_processing(), "Normal battle animation must stay suspended during the kiss")
    check(entrance.audio.playing and same_mp3(entrance.audio.stream, CUTSCENE_PATH), "The close-up must play the supplied cutscene audio")
    check(not fight.music.playing and not fight.chant.playing, "Only the cutscene voice may play during the kiss")
    check(not entrance.audio.stream.loop, "The cutscene audio must play once")
    var voice_start_zoom: Vector2 = entrance.camera.zoom
    var full_audio_length: float = entrance.audio.stream.get_length()
    check(is_equal_approx(entrance.kiss_seconds + entrance.laugh_seconds, full_audio_length), "Kiss and laugh must preserve the full audio interval")

    var paused_phase: String = entrance.phase
    var paused_position: Vector2 = entrance.camera.global_position
    var paused_zoom: Vector2 = entrance.camera.zoom
    var paused_frame: int = visual.frame
    var paused_progress: float = visual.frame_progress
    paused = true
    entrance.sequence.play()
    await create_timer(0.15, true).timeout
    check(entrance.phase == paused_phase and entrance.camera.global_position == paused_position and entrance.camera.zoom == paused_zoom, "Pause must freeze the cinematic camera and timeline")
    check(visual.frame == paused_frame and is_equal_approx(visual.frame_progress, paused_progress), "Pause must freeze Iara's cutscene animation")
    entrance.sequence.pause()
    paused = false

    var laugh_start: float = kiss_start + entrance.kiss_seconds
    var hold_start: float = kiss_start + full_audio_length
    var return_start: float = hold_start + entrance.END_HOLD_SECONDS
    advance_to(entrance.sequence, laugh_start - 0.02)
    check(entrance.phase == "kiss" and fight.boss_intro_running, "The kiss must finish before the laugh starts")
    check(entrance.camera.zoom.x > voice_start_zoom.x, "Iara's kiss must begin one gradual push-in spanning the voice interval")
    var kiss_end_position: Vector2 = entrance.camera.global_position
    var kiss_end_zoom: Vector2 = entrance.camera.zoom
    advance_to(entrance.sequence, laugh_start + 0.002)
    check(entrance.phase == "laugh" and visual.animation == "intro_laugh", "The laugh must follow the complete kiss")
    check(entrance.camera.global_position.distance_to(kiss_end_position) < 1.0 and entrance.camera.zoom.distance_to(kiss_end_zoom) < 0.01, "The camera must stay continuous between kiss and laugh")
    check(not visual.is_processing(), "Normal battle animation must stay suspended during the laugh")
    advance_to(entrance.sequence, hold_start - 0.02)
    check(entrance.phase == "laugh" and fight.boss_intro_running, "The laugh and voice interval must finish before returning to gameplay")
    advance_to(entrance.sequence, hold_start + 0.002)
    check(entrance.phase == "hold" and visual.animation == "intro_laugh", "Hold the final laugh pose for the additional half-second")
    advance_to(entrance.sequence, return_start - 0.02)
    check(entrance.phase == "hold" and hero.control_locked, "The extra final hold must finish before the camera returns")
    advance_to(entrance.sequence, return_start + 0.002)
    check(entrance.phase == "return" and fight.boss_intro_running and hero.control_locked, "The return must keep controls locked")
    advance_to(entrance.sequence, return_start + entrance.RETURN_SECONDS - 0.02)
    check(fight.boss_intro_running, "The camera return must last the requested half-second")
    advance_to(entrance.sequence, return_start + entrance.RETURN_SECONDS + 0.01)
    check(not fight.boss_intro_running and not hero.control_locked and hero.is_physics_processing(), "Finishing the cinematic must restore playable controls")
    check(get_root().get_viewport().get_camera_2d() == gameplay_camera and gameplay_camera.zoom == Vector2(1.8, 1.8) and not gameplay_camera.top_level, "Finishing must restore the normal player-following camera")
    check(visual.animation == "idle" and visual.is_processing(), "Iara must return to her battle idle")
    check(fight.music.playing and same_mp3(fight.music.stream, MUSIC_PATH), "The Iara battle track must start after the cinematic")
    check(is_equal_approx(fight.music.volume_db, fight.original_music_volume), "Iara's battle track must restore normal volume after the approach fade")
    check(fight.state == fight.State.IDLE and fight.state_timer == idle_time, "The playable fight must retain its opening idle interval")
    hero.set_physics_process(false)

    check(fight.sound_effects.players.has("spell") and fight.sound_effects.players.has("hit"), "Iara must load both supplied battle effects")
    if fight.sound_effects.players.has("spell") and fight.sound_effects.players.has("hit"):
        var spell_audio: AudioStreamPlayer = fight.sound_effects.players["spell"]
        var hit_audio: AudioStreamPlayer = fight.sound_effects.players["hit"]
        check(same_mp3(spell_audio.stream, SPELL_PATH) and not spell_audio.stream.loop, "The spell must use the supplied non-looping MP3")
        check(same_mp3(hit_audio.stream, HIT_PATH) and not hit_audio.stream.loop, "The damage cue must use the supplied non-looping MP3")
        var spell_probe := SoundProbe.new()
        var hit_probe := SoundProbe.new()
        fight.sound_effects.players["spell"] = spell_probe
        fight.sound_effects.players["hit"] = hit_probe
        fight._physics_process(fight.state_timer + 0.01)
        fight._physics_process(2.4)
        fight._physics_process(0.02)
        fight._physics_process(0.1)
        check(fight.state == fight.State.CASTING and spell_probe.plays == 1, "Preparing and releasing a spell must play its effect exactly once")
        fight.boss.take_damage(1)
        check(hit_probe.plays == 0, "A protected boss must not play a damage cue")
        fight.state = fight.State.VULNERABLE
        fight.boss.take_damage(0)
        fight.boss.take_damage(1)
        check(fight.boss.hp == fight.boss.max_hp - 1 and hit_probe.plays == 1, "An accepted strike must reduce HP and play one damage cue")
        fight.state = fight.State.PREPARING
        fight.boss.take_damage(1)
        check(hit_probe.plays == 1, "Rejected strikes must not replay the damage cue")
        fight.sound_effects.players["spell"] = spell_audio
        fight.sound_effects.players["hit"] = hit_audio

    fight._reset_scene()
    while root.get_node("SceneTransition").busy:
        await process_frame
    fight = current_scene
    check(fight.boss_intro_running and fight.entrance.phase == "player" and fight.player.control_locked, "A checkpoint retry must replay the whole Iara introduction")
    check(fight.boss.hp == fight.boss.max_hp and fight.player.hp == hero_hp, "A retry must reset both actors' health")
    check(not fight.music.playing and not fight.entrance.audio.playing, "A retry must not carry over battle music or the previous voice")
    fight.entrance.finish()
    check(not fight.boss_intro_running and not fight.player.control_locked and fight.player.is_physics_processing(), "Finishing a replayed introduction must restore gameplay")

    # An interrupted voice must leave no cinematic camera, particles or music.
    var abort_probe := preload("res://scripts/IaraEntrance.gd").new()
    fight.add_child(abort_probe)
    abort_probe.start(fight)
    abort_probe.sequence.pause()
    advance_to(abort_probe.sequence, kiss_start + abort_probe.kiss_seconds * 0.5)
    check(abort_probe.audio.playing, "The abort check must interrupt the active kiss voice")
    abort_probe.abort()
    check(abort_probe.finished and not abort_probe.audio.playing and not fight.boss_intro_running, "Aborting must stop the cinematic timeline and voice")
    check(abort_probe.camera.is_queued_for_deletion() and abort_probe.glimmer.is_queued_for_deletion() and abort_probe.letterbox.is_queued_for_deletion(), "Aborting must remove the cinematic camera and visual effects")
    check(fight.player.get_node("Camera2D").is_current() and fight.get_node("HUD").visible, "Aborting must restore the gameplay camera and HUD")
    check(not fight.player.is_physics_processing() and not fight.music.playing, "Aborting must not start combat or battle music")
    abort_probe.finish()
    check(not fight.music.playing and not fight.player.is_physics_processing(), "Finishing an already aborted introduction must not restart the fight")
    if failures == 0:
        print("PASS: Iara continuous close-ups/pan, kiss then laugh, full voice interval, half-second return, immunity, pause, battle music/effects, checkpoint replay and abort cleanup")
    quit(0 if failures == 0 else 1)
