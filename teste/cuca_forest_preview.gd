extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    # The scene saves checkpoints in _ready; keep every preview save isolated.
    if not OS.get_environment("APPDATA").contains("stage5-"):
        push_error("Use an isolated APPDATA directory named stage5-* for this preview")
        quit(1)
        return
    create_timer(45.0, true).timeout.connect(func(): quit(1))
    root.size = Vector2i(1280, 720)
    var output := ProjectSettings.globalize_path("res://.validation/stage5-previews")
    DirAccess.make_dir_recursive_absolute(output)
    var view := SubViewport.new()
    view.size = Vector2i(1280, 720)
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var level = load("res://floresta5.tscn").instantiate()
    view.add_child(level)
    freeze(level)
    level.player.position = Vector2(480.0, 450.0)
    await capture_frame(view, level, output, "first")

    await defeat_wave(level, 0)
    level._process(0.0)
    level.player.position = Vector2(1110.0, 450.0)
    await capture_frame(view, level, output, "hole")

    level.player.position.x = level.SECOND_STAGE_GATE
    level._process(0.0)
    freeze(level)
    level.player.position = Vector2(1960.0, 450.0)
    await capture_frame(view, level, output, "second")

    await defeat_wave(level, 1)
    level._process(0.0)
    level.player.position.x = level.THIRD_STAGE_GATE
    level._process(0.0)
    freeze(level)
    level.player.position = Vector2(3240.0, 450.0)
    await capture_frame(view, level, output, "third")

    await defeat_wave(level, 2)
    level._process(0.0)
    level.player.position = Vector2(level.CAVE_TRIGGER_X - 1.0, 480.0)
    level._process(0.0)
    await capture_frame(view, level, output, "cave")

    # A wider art review shows the full canopy, ruins and cave composition.
    var review_camera := Camera2D.new()
    review_camera.position = Vector2(3890.0, 370.0)
    review_camera.zoom = Vector2.ONE * 1.2
    level.add_child(review_camera)
    review_camera.make_current()
    level.get_node("HUD").hide()
    await capture_frame(view, level, output, "cave-wide", review_camera)

    var gameplay_camera := level.player.get_node("Camera2D") as Camera2D
    gameplay_camera.make_current()
    review_camera.free()
    level.player.position = Vector2(3730.0, 480.0)
    gameplay_camera.reset_smoothing()
    gameplay_camera.force_update_scroll()
    level._process(0.0)
    # Stop game time along the longer entry path. Rendering remains live,
    # so these frames review the real exit without completing the fixture.
    level.cave_entry_tween.pause()
    await capture_frame(view, level, output, "entry-start", level.cave_camera)
    level.cave_entry_tween.custom_step(1.65)
    await capture_frame(view, level, output, "entry-approach", level.cave_camera)
    var at_door := false
    for _step in range(400):
        level.cave_entry_tween.custom_step(0.025)
        if level.player.position.distance_to(level.CAVE_DOOR) < 14.0:
            at_door = true
            break
    if not at_door:
        push_error("The entry preview did not reach the cave opening")
        quit(1)
        return
    await capture_frame(view, level, output, "entry-door", level.cave_camera)
    level.free()
    view.free()
    print("PASS: phase-five first/hole/second/third/cave/cave-wide/entry-start/entry-approach/entry-door previews captured at 1280x720; " + output)
    quit()

func freeze(level: Node) -> void:
    level.set_process(false)
    level.set_physics_process(false)
    for actor in get_nodes_in_group("player") + get_nodes_in_group("enemy"):
        if actor.get("spawn_tween") != null and actor.spawn_tween.is_valid():
            actor.spawn_tween.custom_step(3.0)
        actor.set_physics_process(false)

func defeat_wave(level: Node, index: int) -> void:
    for enemy in level.waves[index]:
        if is_instance_valid(enemy) and enemy.hp > 0:
            enemy.take_damage(enemy.hp)
    await process_frame
    while not get_nodes_in_group("enemy_defeat_visuals").is_empty():
        await process_frame

func capture_frame(view: SubViewport, level: Node, output: String, phase: String, custom_camera: Camera2D = null) -> void:
    level._update_hud()
    var camera := custom_camera if custom_camera != null else level.player.get_node("Camera2D") as Camera2D
    camera.make_current()
    camera.reset_smoothing()
    camera.force_update_scroll()
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var error := view.get_texture().get_image().save_png(output.path_join(phase + ".png"))
    if error != OK:
        push_error("Could not save " + phase + " preview: " + str(error))
        quit(1)
