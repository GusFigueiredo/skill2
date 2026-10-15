extends SceneTree

var failures := 0

func _initialize() -> void:
    call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error(message)

func run_checks() -> void:
    if not OS.get_environment("APPDATA").contains("parallax-"):
        push_error("Use an isolated APPDATA directory named parallax-* for scenery checks")
        quit(1)
        return
    create_timer(45.0, true).timeout.connect(func():
        push_error("Stage scenery checks timed out")
        quit(1)
    )
    root.size = Vector2i(1280, 720)
    for scene_path: String in ["res://main.tscn", "res://ratanaba2.tscn", "res://rio_negro3.tscn", "res://rio_negro4.tscn"]:
        var level: Node2D = load(scene_path).instantiate()
        root.add_child(level)
        freeze(level)
        var physical_before: Dictionary = physical_state(level)
        await settle()
        check(level.has_node("StageScenery"), "Every earlier stage must install scenery: " + scene_path)
        if level.has_node("StageScenery"):
            await check_scenery(level, scene_path)
        var physical_after: Dictionary = physical_state(level)
        if physical_after != physical_before:
            for key: Variant in physical_before:
                if physical_before[key] != physical_after.get(key):
                    print("Changed physical fixture: ", key, " before=", physical_before[key], " after=", physical_after.get(key))
        check(physical_after == physical_before, "Scenery must preserve ground, holes, actors and collisions: " + scene_path)
        level.free()
        await process_frame

    var cave_level: Node2D = load("res://floresta5.tscn").instantiate()
    root.add_child(cave_level)
    freeze(cave_level)
    await settle()
    check(not cave_level.has_node("StageScenery"), "Phase five must retain its original dedicated parallax")
    cave_level.free()
    print("PASS: actual background parallax in phases 1–4, active cutscene cameras, fixed ground/actors/holes/collisions, pause/resume and original phase-five scenery" if failures == 0 else "FAIL: %d stage scenery checks" % failures)
    quit(1 if failures else 0)

func check_scenery(level: Node2D, scene_path: String) -> void:
    var scenery: Node = level.get_node("StageScenery")
    var background: Sprite2D = level.get_node("Background")
    var gameplay_camera: Camera2D = level.player.get_node("Camera2D")
    var original_zoom: Vector2 = gameplay_camera.zoom
    check(scenery.configured and scenery.background == background, "Scenery must configure the actual backdrop: " + scene_path)
    check(is_equal_approx(scenery.parallax_factor, 0.13), "Backdrop depth must remain subtle and consistent: " + scene_path)
    if level.stage_index == 3:
        check(is_equal_approx(scenery.base_background_position.y, -80.0), "Iara's late background placement must be captured after inherited ready")
    check(gameplay_camera.zoom == Vector2(1.8, 1.8), "Scenery must preserve normal gameplay framing: " + scene_path)
    check(gameplay_camera.limit_top == 180 and gameplay_camera.limit_bottom == 580, "Scenery must preserve vertical camera limits: " + scene_path)
    check(level.get_node("HUD/HealthBar").visible, "Scenery must preserve the health HUD: " + scene_path)

    gameplay_camera.reset_smoothing()
    gameplay_camera.force_update_scroll()
    await settle()
    var initial_background: Vector2 = background.position
    var original_camera_position: Vector2 = gameplay_camera.get_screen_center_position()
    var cinematic := Camera2D.new()
    cinematic.name = "SceneryCheckCutsceneCamera"
    cinematic.zoom = original_zoom
    cinematic.position = original_camera_position
    level.add_child(cinematic)
    cinematic.make_current()
    cinematic.force_update_scroll()
    await settle()
    check(background.position.is_equal_approx(initial_background), "Changing to an aligned temporary camera must not jump the background: " + scene_path)
    var before: Vector2 = background.position
    var center_before: Vector2 = cinematic.get_screen_center_position()
    cinematic.position.x += 100.0
    cinematic.force_update_scroll()
    await settle()
    var movement: Vector2 = cinematic.get_screen_center_position() - center_before
    var expected_shift := Vector2(movement.x * float(scenery.parallax_factor), 0.0)
    check((background.position - before).is_equal_approx(expected_shift), "A 100px active-camera pan must move the real background by 13px: " + scene_path)
    check(absf(background.position.x - before.x) > 12.0, "The background must visibly move independently of the ground: " + scene_path)

    # A wide closeup pan is the same camera path used by the boss entrances.
    cinematic.position.x += 300.0
    cinematic.zoom = original_zoom * 1.4
    cinematic.force_update_scroll()
    await settle()
    var expected_position: Vector2 = scenery.base_background_position + Vector2((cinematic.get_screen_center_position().x - scenery.anchor_center.x) * float(scenery.parallax_factor), 0.0)
    check(background.position.is_equal_approx(expected_position), "Boss pans must use the active camera without resetting the parallax origin: " + scene_path)
    check(gameplay_camera.zoom == original_zoom, "Boss-camera scenery must not change the gameplay zoom: " + scene_path)
    gameplay_camera.make_current()
    gameplay_camera.reset_smoothing()
    gameplay_camera.force_update_scroll()
    await settle()
    check(background.position.is_equal_approx(initial_background), "Returning from the cutscene camera must recover the same backdrop framing: " + scene_path)
    cinematic.free()
    await check_paused_effects(level)

func check_paused_effects(level: Node) -> void:
    var animated: Array[Node] = []
    collect_clocks(level, animated)
    check(not animated.is_empty(), "Scenery must have animated atmospheric effects")
    var before: Dictionary = clock_state(animated)
    await create_timer(0.06, true).timeout
    var running: Dictionary = clock_state(animated)
    for node: Node in animated:
        check(float(running[node]) > float(before[node]), "Atmosphere must animate during gameplay: " + str(node.name))
    paused = true
    var paused_values: Dictionary = clock_state(animated)
    await create_timer(0.06, true).timeout
    check(clock_state(animated) == paused_values, "All atmosphere must freeze with the pause menu")
    paused = false
    await create_timer(0.06, true).timeout
    var resumed: Dictionary = clock_state(animated)
    for node: Node in animated:
        check(float(resumed[node]) > float(paused_values[node]), "Atmosphere must resume after pausing: " + str(node.name))

func collect_clocks(node: Node, output: Array[Node]) -> void:
    var script: Script = node.get_script()
    var atmosphere: bool = script != null and script.resource_path in ["res://scripts/StageScenery.gd", "res://scripts/Atmosphere.gd", "res://scripts/RiverWeather.gd", "res://scripts/RiverRainGround.gd"]
    for property: Dictionary in node.get_property_list():
        if atmosphere and property.name in ["clock", "elapsed"]:
            output.append(node)
            break
    for child: Node in node.get_children():
        collect_clocks(child, output)

func clock_state(nodes: Array[Node]) -> Dictionary:
    var result: Dictionary = {}
    for node: Node in nodes:
        var value: Variant = node.get("clock")
        result[node] = value if value != null else node.get("elapsed")
    return result

func physical_state(level: Node2D) -> Dictionary:
    var result: Dictionary = {"pits": level.pits.duplicate(), "arena": level.arena_bounds, "player": level.player.transform}
    for node_name: String in ["Ground", "BossGround"]:
        if level.has_node(node_name):
            var ground: Sprite2D = level.get_node(node_name)
            result[node_name] = [ground.transform, ground.region_rect, ground.texture, ground.z_index]
    collect_collision_state(level, level, result)
    return result

func collect_collision_state(node: Node, level: Node, output: Dictionary) -> void:
    var path: String = str(level.get_path_to(node))
    if node is CollisionObject2D:
        output[path] = [node.transform, node.collision_layer, node.collision_mask]
    elif node is CollisionShape2D:
        output[path] = [node.transform, node.shape, node.shape.get_rect(), node.disabled]
    for child: Node in node.get_children():
        collect_collision_state(child, level, output)

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
        var visual: AnimatedSprite2D = actor.get_node("Sprite")
        # Iara's normal animated hitbox follows each idle-frame silhouette.
        # Hold the source pose so a camera-only check compares the same shape.
        visual.pause()
        visual.set_process(false)

func settle() -> void:
    await process_frame
    await process_frame
    await process_frame
