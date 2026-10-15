extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    root.size = Vector2i(1280, 720)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.validation"))
    change_scene_to_file("res://rio_negro3.tscn")
    await process_frame
    await process_frame
    var level = current_scene
    freeze(level)
    level.player.position = Vector2(500, 460)
    reset_camera(level)
    await capture_frame("stage3")

    change_scene_to_file("res://rio_negro4.tscn")
    await process_frame
    await process_frame
    var fight = current_scene
    freeze(fight)
    fight.player.position = Vector2(1700, 460)
    reset_camera(fight)
    await capture_frame("stage4-approach")
    preload("res://iara_test_support.gd").prepare_fight(fight)
    freeze(fight)
    fight.player.position = fight.boss_point(Vector2(420, 460))
    reset_camera(fight)
    fight._physics_process(fight.state_timer + 0.01)
    fight._physics_process(fight.PREPARATION_SECONDS * 0.62)
    fight.boss.get_node("Sprite")._process(0.0)
    fight.river_effects.clock = 4.2
    fight.river_effects.set_process(false)
    fight.river_effects.queue_redraw()
    await capture_frame("stage4-preparation")
    fight._physics_process(fight.state_timer + 0.01)
    fight._physics_process(fight.CAST_SECONDS * 0.5)
    fight.boss.get_node("Sprite")._process(0.13)
    fight.boss.get_node("Sprite").set_frame_and_progress(2, 0)
    fight.river_effects.queue_redraw()
    await capture_frame("stage4-launch")
    fight._physics_process(fight.state_timer + 0.01)
    freeze(fight)
    if fight.camera_tween != null and fight.camera_tween.is_valid():
        fight.camera_tween.custom_step(0.4)
    fight._process(0.0)
    fight.key_prompt._process(0.03)
    fight.river_effects.queue_redraw()
    await capture_frame("stage4-trance")
    print("PASS: Rio Negro rain and Iara preparation/launch/trance previews captured")
    quit()

func freeze(level: Node) -> void:
    level.set_process(false)
    level.set_physics_process(false)
    for actor in get_nodes_in_group("player") + get_nodes_in_group("enemy"):
        if "spawn_tween" in actor and actor.spawn_tween != null and actor.spawn_tween.is_valid():
            actor.spawn_tween.custom_step(3.0)
        actor.set_physics_process(false)

func reset_camera(level: Node) -> void:
    var camera: Camera2D = level.player.get_node("Camera2D")
    camera.reset_smoothing()
    camera.force_update_scroll()

func capture_frame(phase: String) -> void:
    var weather = current_scene.get_node("RiverWeather")
    weather.clock = 7.8
    weather._process(0.0)
    weather.set_process(false)
    var ground = current_scene.get_node("RiverRainGround")
    ground.clock = 7.8
    ground._process(0.0)
    ground.set_process(false)
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var rendered := root.get_texture().get_image()
    if rendered == null or rendered.is_empty():
        push_error("The weather preview needs normal rendering rather than --headless")
        quit(1)
        return
    var path := "res://.validation/rio-weather-%s.png" % phase
    var result := rendered.save_png(path)
    print("CAPTURE: %s (%s)" % [path, result])
