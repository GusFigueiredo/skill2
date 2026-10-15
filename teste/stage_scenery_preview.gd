extends SceneTree

var output: String
var view: SubViewport

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    if not OS.get_environment("APPDATA").contains("parallax-"):
        push_error("Use an isolated APPDATA directory named parallax-* for scenery previews")
        quit(1)
        return
    create_timer(60.0, true).timeout.connect(func():
        push_error("Stage scenery previews timed out")
        quit(1)
    )
    root.size = Vector2i(1280, 720)
    output = ProjectSettings.globalize_path("res://.validation/parallax-previews")
    DirAccess.make_dir_recursive_absolute(output)
    view = SubViewport.new()
    view.size = Vector2i(1280, 720)
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    for scene_path: String in ["res://main.tscn", "res://ratanaba2.tscn", "res://rio_negro3.tscn", "res://rio_negro4.tscn"]:
        var level: Node2D = load(scene_path).instantiate()
        view.add_child(level)
        freeze(level)
        await settle()
        var stage: int = level.stage_index + 1
        level.player.position = Vector2(480.0, 450.0)
        await capture_frame(level, "phase%d-first" % stage)

        # The same ground and actors stay fixed while only the active camera pans.
        # This pair makes the real background/foreground separation reviewable.
        var original: Camera2D = level.player.get_node("Camera2D")
        var pan := Camera2D.new()
        pan.position = original.get_screen_center_position()
        pan.zoom = original.zoom
        level.add_child(pan)
        pan.make_current()
        await capture_frame(level, "phase%d-pan-before" % stage, pan)
        pan.position.x += 300.0
        await capture_frame(level, "phase%d-pan-after" % stage, pan)
        original.make_current()
        pan.free()

        level.player.position = Vector2(1880.0, 450.0)
        await capture_frame(level, "phase%d-second" % stage)
        # Repeated source-art boundaries must stay hidden during long traversal.
        level.player.position = Vector2(2345.0, 450.0)
        await capture_frame(level, "phase%d-long-pan" % stage)
        level.free()
        await process_frame

    await capture_boitata_intro()
    await capture_iara_intro()
    view.free()
    print("PASS: 1280x720 phase 1–4 scenery, paired 300px camera pans, long traversal, Boitata zoom and Iara entrance previews; " + output)
    quit()

func capture_boitata_intro() -> void:
    var fight: Node2D = load("res://ratanaba2.tscn").instantiate()
    view.add_child(fight)
    freeze(fight)
    await settle()
    fight.boss_area_entered = true
    fight.wave_index = 2
    fight.boss_landing_position = Vector2(2750.0, 450.0)
    fight.player.position = fight.boss_landing_position + Vector2(fight.BOSS_ENTRY_WALK_DISTANCE, 0.0)
    var original: Camera2D = fight.player.get_node("Camera2D")
    original.reset_smoothing()
    original.force_update_scroll()
    fight._start_boss_intro()
    var timeline: Tween = fight.boss_intro_tween
    timeline.pause()
    var phase_time: float = fight.BOSS_APPROACH_SECONDS + fight.BOSS_REVEAL_SECONDS + 0.35
    timeline.custom_step(phase_time)
    for child: Node in fight.get_children():
        if child.get_script() == preload("res://scripts/BossEntrance.gd"):
            child.elapsed = phase_time
            child.roar_elapsed = 0.35
            child.title_progress = 1.0
    freeze(fight)
    await capture_frame(fight, "phase2-boitata-zoom", view.get_camera_2d())
    fight.free()
    await process_frame

func capture_iara_intro() -> void:
    var fight: Node2D = load("res://rio_negro4.tscn").instantiate()
    view.add_child(fight)
    freeze(fight)
    await settle()
    preload("res://iara_test_support.gd").reach_boss(fight)
    freeze(fight)
    var intro: Node = fight.entrance
    intro.sequence.pause()
    intro.letterbox.elapsed = 1.0
    var boss_arrival: float = intro.PLAYER_ZOOM_SECONDS + intro.PLAYER_HOLD_SECONDS + intro.IARA_TRAVEL_SECONDS
    intro.sequence.custom_step(boss_arrival + intro.IARA_HOLD_SECONDS * 0.5)
    freeze(fight)
    await capture_frame(fight, "phase4-iara-intro", view.get_camera_2d())
    intro.sequence.custom_step(intro.IARA_HOLD_SECONDS + intro.kiss_seconds + intro.laugh_seconds + intro.END_HOLD_SECONDS + intro.RETURN_SECONDS + 0.1)
    freeze(fight)
    await capture_frame(fight, "phase4-iara-arena")
    fight.free()
    await process_frame

func capture_frame(level: Node2D, phase: String, custom_camera: Camera2D = null) -> void:
    level._update_hud()
    var camera: Camera2D = custom_camera if custom_camera != null else level.player.get_node("Camera2D")
    camera.make_current()
    camera.reset_smoothing()
    camera.force_update_scroll()
    await settle()
    await RenderingServer.frame_post_draw
    var result: Error = view.get_texture().get_image().save_png(output.path_join(phase + ".png"))
    if result != OK:
        push_error("Could not save " + phase + " preview: " + str(result))
        quit(1)

func freeze(level: Node) -> void:
    level.set_process(false)
    level.set_physics_process(false)
    if level.get("tutorial") != null:
        level.tutorial.step = level.tutorial.Step.COMPLETE
        level.tutorial.hide()
        level.tutorial.set_process(false)
    for actor: Node in get_nodes_in_group("player") + get_nodes_in_group("enemy"):
        var spawn: Tween = actor.get("spawn_tween")
        if spawn != null and spawn.is_valid():
            spawn.custom_step(3.0)
        actor.set_physics_process(false)

func settle() -> void:
    await process_frame
    await process_frame
    await process_frame
