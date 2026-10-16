extends SceneTree

var output: String
var view: SubViewport

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    if not OS.get_environment("APPDATA").contains("cave6-"):
        push_error("Use an isolated APPDATA directory containing cave6- for cave previews")
        quit(1)
        return
    create_timer(60.0, true).timeout.connect(func():
        push_error("Cave previews timed out")
        quit(1)
    )
    root.size = Vector2i(1280, 720)
    output = ProjectSettings.globalize_path("res://.validation/cave6-ceiling-previews")
    DirAccess.make_dir_recursive_absolute(output)
    view = SubViewport.new()
    view.size = Vector2i(1280, 720)
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var level: Node2D = load("res://caverna6.tscn").instantiate()
    view.add_child(level)
    freeze(level)
    await settle()
    level.player.position = Vector2(480, 450)
    await capture_frame(level, "first")

    await defeat_wave(level, 0)
    level._process(0)
    level.player.position = Vector2(level.SECOND_STAGE_GATE, 450)
    level._process(0)
    freeze(level)
    level.player.position = Vector2(2100, 450)
    await capture_frame(level, "second")
    await defeat_wave(level, 1)
    level._process(0)
    level.player.position = Vector2(2590, 450)
    await capture_frame(level, "gap-second-to-third")

    level.player.position = Vector2(level.THIRD_STAGE_GATE, 450)
    level._process(0)
    freeze(level)
    level.player.position = Vector2(3380, 450)
    await capture_frame(level, "third")

    # A single fixture rock is driven through its real warning/fall/shatter
    # states while every ordinary encounter actor remains frozen.
    level.player.position = Vector2(3400, 450)
    var hazard := preload("res://scripts/CaveStalactite.gd").new()
    hazard.configure(level, Vector2(3420, 150), 450, true, 2)
    level.add_child(hazard)
    hazard.set_physics_process(false)
    hazard._begin_warning(level.player)
    hazard._physics_process(0.50)
    await capture_frame(level, "stalactite-warning")
    hazard._begin_fall()
    hazard._physics_process(0.32)
    await capture_frame(level, "stalactite-falling")
    hazard._physics_process(0.35)
    hazard.visual.set_frame_and_progress(1, 0)
    await capture_frame(level, "stalactite-shatter")

    # Review the visible ceiling at gameplay scale, with no wall torches.
    var review_camera := Camera2D.new()
    review_camera.position = Vector2(3730, 300)
    review_camera.zoom = Vector2.ONE * 2.2
    level.add_child(review_camera)
    level.get_node("HUD").hide()
    await capture_frame(level, "ceiling-without-torches", review_camera)
    review_camera.queue_free()
    level.get_node("HUD").show()

    await defeat_wave(level, 2)
    level._process(0)
    level.player.position = Vector2(4030, 450)
    await capture_frame(level, "current-endpoint")
    level.get_node("HUD").hide()
    var wide := Camera2D.new()
    wide.position = Vector2(2140, 370)
    wide.zoom = Vector2.ONE * 1.15
    level.add_child(wide)
    await capture_frame(level, "cave-wide", wide)
    level.free()
    view.free()
    print("PASS: phase-six first/second/gap/third, ceiling without torches, warning/fall/shatter, endpoint and wide previews rendered at 1280x720; " + output)
    quit()

func capture_frame(level: Node2D, phase: String, custom_camera: Camera2D = null) -> void:
    level._update_hud()
    var camera: Camera2D = custom_camera if custom_camera != null else level.player.get_node("Camera2D")
    camera.make_current()
    camera.reset_smoothing()
    camera.force_update_scroll()
    await settle()
    await RenderingServer.frame_post_draw
    var result := view.get_texture().get_image().save_png(output.path_join(phase + ".png"))
    if result != OK:
        push_error("Could not save " + phase + " preview: " + str(result))
        quit(1)

func freeze(level: Node) -> void:
    level.set_process(false)
    level.set_physics_process(false)
    for actor in get_nodes_in_group("player") + get_nodes_in_group("enemy"):
        var spawn: Tween = actor.get("spawn_tween")
        if spawn != null and spawn.is_valid():
            spawn.custom_step(3.0)
        actor.set_physics_process(false)
    for hazard: Node in level.stalactites:
        hazard.process_mode = Node.PROCESS_MODE_DISABLED

func defeat_wave(level: Node, index: int) -> void:
    for enemy in level.waves[index]:
        if is_instance_valid(enemy) and enemy.hp > 0:
            enemy.take_damage(enemy.hp)
    await process_frame

func settle() -> void:
    await process_frame
    await process_frame
    await process_frame
