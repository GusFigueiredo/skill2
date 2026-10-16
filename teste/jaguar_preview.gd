extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    # The forest saves checkpoints during setup; isolate every visual review.
    if not OS.get_environment("APPDATA").contains("jaguar-"):
        push_error("Use an isolated APPDATA directory named jaguar-* for this preview")
        quit(1)
        return
    create_timer(60.0, true).timeout.connect(func(): quit(1))
    root.size = Vector2i(1280, 720)
    var output := ProjectSettings.globalize_path("res://.validation/jaguar-previews")
    DirAccess.make_dir_recursive_absolute(output)
    var view := SubViewport.new()
    view.size = Vector2i(1280, 720)
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var level = load("res://floresta5.tscn").instantiate()
    view.add_child(level)
    freeze(level)
    var cat = level.jaguars[0]
    var hero = level.player
    hero.position = Vector2(775, 420)
    await capture_frame(view, output, "01-hidden-bush")
    cat._physics_process(0.01)
    cat._physics_process(0.42)
    cat.visual.pause()
    cat.visual.frame = 2
    await capture_frame(view, output, "02-emerging")
    cat._physics_process(cat.RUSTLE_SECONDS - cat.state_timer + 0.01)
    cat._physics_process(0.32)
    await capture_frame(view, output, "03-ambush-pounce")
    cat._physics_process(0.37)
    var grapple = level.active_jaguar_grapple
    if not is_instance_valid(grapple):
        push_error("The preview ambush did not start its ground struggle")
        quit(1)
        return
    grapple.set_process(false)
    grapple.prompt.set_process(false)
    advance_grapple(grapple, 0.7, "struggle")
    advance_grapple(grapple, 0.17)
    grapple.prompt.flash_time = 0.0
    grapple.prompt._refresh_visuals()
    await capture_frame(view, output, "04-struggle-k-normal")
    tap(grapple)
    await capture_frame(view, output, "05-struggle-k-pressed")
    for _tap in range(12):
        advance_grapple(grapple, 0.19)
        if grapple.phase != "struggle":
            break
        tap(grapple)
    advance_grapple(grapple, 0.24)
    await capture_frame(view, output, "06-expel-jaguar")
    advance_grapple(grapple, 3.0)
    await process_frame
    freeze(level)

    var camera = hero.get_node("Camera2D")
    camera.make_current()
    for index in range(3):
        cat.position = Vector2(860, 450)
        hero.position = Vector2(950, 450)
        hero.damage_cooldown = 99.0
        cat.recovery_push = Vector2.ZERO
        cat.attack_number = index
        cat.attack_cooldown_timer = 0.0
        cat._change_state(cat.State.PURSUE)
        cat._physics_process(0.001)
        cat._physics_process(cat.state_duration * 0.65)
        var kind: String = ["paw", "bite", "leap"][index]
        await capture_frame(view, output, "07-warning-" + kind)
        cat._physics_process(cat.state_duration - cat.state_timer + 0.01)
        cat._physics_process(0.30 if kind == "leap" else 0.14)
        cat.visual.pause()
        if kind != "leap":
            cat.visual.frame = 1
        await capture_frame(view, output, "08-attack-" + kind)

    # The second occupied bush should compose naturally with the final forest
    # approach; this review preserves the cave's existing early trigger.
    await defeat_wave(level, 0)
    level._process(0.0)
    hero.position = Vector2(level.SECOND_STAGE_GATE, 450)
    level._process(0.0)
    freeze(level)
    hero.position = Vector2(1940, 450)
    level._update_hud()
    await capture_frame(view, output, "09-upper-bush-second-section")
    await defeat_wave(level, 1)
    level._process(0.0)
    hero.position = Vector2(level.THIRD_STAGE_GATE, 450)
    level._process(0.0)
    freeze(level)
    hero.position = Vector2(3290, 475)
    level._update_hud()
    await capture_frame(view, output, "09-third-section-bush")
    level.free()
    view.free()
    print("PASS: jaguar hidden bush, emergence, arc, single normal/pressed K, expulsion, three combat warnings/strikes and upper-edge bush previews across all sections; " + output)
    quit()

func tap(grapple: Node) -> void:
    for pressed: bool in [true, false]:
        var event := InputEventKey.new()
        event.keycode = KEY_K
        event.physical_keycode = KEY_K
        event.pressed = pressed
        grapple._input(event)

func advance_grapple(grapple: Node, seconds: float, stop_phase: String = "") -> void:
    for _frame in range(ceili(seconds * 60.0)):
        if not is_instance_valid(grapple) or grapple.is_queued_for_deletion() or grapple.phase == "finished" or (not stop_phase.is_empty() and grapple.phase == stop_phase):
            return
        grapple._process(1.0 / 60.0)
        if is_instance_valid(grapple) and grapple.phase in ["pushing", "return"]:
            grapple.jaguar._physics_process(1.0 / 60.0)

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
            if enemy.has_method("finish_grapple"):
                enemy.finish_grapple(true)
            enemy.take_damage(enemy.hp)
    await process_frame

func capture_frame(view: SubViewport, output: String, phase: String) -> void:
    var camera := view.get_camera_2d()
    camera.reset_smoothing()
    camera.force_update_scroll()
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var error := view.get_texture().get_image().save_png(output.path_join(phase + ".png"))
    if error != OK:
        push_error("Could not save " + phase + " preview: " + str(error))
        quit(1)
