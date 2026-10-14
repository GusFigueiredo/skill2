extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    create_timer(30.0, true).timeout.connect(func(): quit(1))
    var output := OS.get_environment("TEMP").path_join("skill2-iara-course-previews")
    DirAccess.make_dir_recursive_absolute(output)
    var view := SubViewport.new()
    view.size = Vector2i(1280, 720)
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var level = load("res://rio_negro4.tscn").instantiate()
    view.add_child(level)
    freeze(level)
    level.player.position.x = 550
    await capture_frame(view, level, output, "first")
    for enemy in level.waves[0]:
        enemy.hp = 0
        level._set_enemy_active(enemy, false)
    level._process(0.0)
    level.player.position.x = 940
    await capture_frame(view, level, output, "hole")
    level.player.position.x = level.SECOND_STAGE_GATE
    level._process(0.0)
    freeze(level)
    level.player.position.x = 2070
    await capture_frame(view, level, output, "second")
    for enemy in level.waves[1]:
        enemy.hp = 0
        level._set_enemy_active(enemy, false)
    level._process(0.0)
    level.player.position.x = level.BOSS_GATE - 80
    await capture_frame(view, level, output, "continuous-path")
    level.player.position.x = level.BOSS_GATE
    level._process(0.0)
    level.entrance.finish()
    freeze(level)
    await capture_frame(view, level, output, "boss")
    level.free()
    view.free()
    print("PASS: first/second waves, hole, continuous path and Iara arena captured; " + output)
    quit()

func freeze(level: Node) -> void:
    level.set_process(false)
    level.set_physics_process(false)
    for actor in get_nodes_in_group("player") + get_nodes_in_group("enemy"):
        if actor.get("spawn_tween") != null and actor.spawn_tween.is_valid():
            actor.spawn_tween.custom_step(3.0)
        actor.set_physics_process(false)

func capture_frame(view: SubViewport, level: Node, output: String, phase: String) -> void:
    level._update_chant()
    level._update_hud()
    var camera := level.player.get_node("Camera2D") as Camera2D
    camera.reset_smoothing()
    camera.force_update_scroll()
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    view.get_texture().get_image().save_png(output.path_join(phase + ".png"))
