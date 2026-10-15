extends SceneTree

var failures := 0

func _initialize() -> void:
    call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error(message)

func run_checks() -> void:
    create_timer(30.0, true).timeout.connect(func():
        push_error("Rio Negro weather checks timed out")
        quit(1)
    )
    for scene_path in ["res://main.tscn", "res://ratanaba2.tscn", "res://rio_negro3.tscn", "res://rio_negro4.tscn"]:
        var level = load(scene_path).instantiate()
        root.add_child(level)
        freeze(level)
        var is_river: bool = level.stage_index in [2, 3]
        check(level.has_node("RiverWeather") == is_river, "Rain must appear only in Rio Negro stages: " + scene_path)
        check(level.has_node("RiverRainGround") == is_river, "Ground rain must appear only in Rio Negro stages: " + scene_path)
        var warm_atmosphere := false
        for child in level.get_children():
            var script: Script = child.get_script()
            if script != null and script.resource_path == "res://scripts/Atmosphere.gd":
                warm_atmosphere = true
        check(warm_atmosphere != is_river, "The river must replace the warm forest fireflies")
        var camera: Camera2D = level.player.get_node("Camera2D")
        check(camera.zoom == Vector2(1.8, 1.8) and not camera.top_level, "Weather must retain the ordinary following camera")
        check(camera.limit_top == 180 and camera.limit_bottom == 580, "Weather must preserve scenery-safe camera limits")
        check(level.get_node("HUD/HealthBar").visible, "Health HUD must remain visible")
        check(level.get_node("HUD/AttackCooldown").visible and level.get_node("HUD/DodgeCooldown").visible, "Weather must preserve the ability HUD")
        if is_river and level.has_node("RiverWeather"):
            await check_weather(level)
            if level.stage_index == 3:
                check_iara_cycle(level)
        level.free()
        await process_frame
    print("PASS: river-only rain, HUD/input layering, pause, normal camera and Iara charm cycle" if failures == 0 else "FAIL: %d river weather checks" % failures)
    quit(1 if failures else 0)

func check_weather(level: Node) -> void:
    var weather: CanvasLayer = level.get_node("RiverWeather")
    var ground: Node2D = level.get_node("RiverRainGround")
    check(weather.layer < level.get_node("HUD").layer, "Weather must render below the HUD")
    check(ground.z_index >= level.get_node("Ground").z_index and ground.z_index < level.player.get_node("Sprite").z_index + 1, "Ground rain must stay on the ground rather than above character effects")
    check_controls_ignore_mouse(weather)
    check(weather.screen != null and weather.mist != null, "Rain and mist must both be installed")
    check(weather.mist.material is ShaderMaterial, "River mist must use its atmosphere shader")
    check(level.get_node("Background").modulate.b > level.get_node("Background").modulate.r, "Background must use cool storm colors")
    check(level.get_node("Ground").modulate.b > level.get_node("Ground").modulate.r, "Ground must use cool storm colors")
    var before: float = weather.clock
    var ground_before: float = ground.clock
    await create_timer(0.05, true).timeout
    check(weather.clock > before, "Rain must animate during ordinary play")
    check(ground.clock > ground_before, "Ground splashes must animate during ordinary play")
    paused = true
    var paused_clock: float = weather.clock
    var paused_ground_clock: float = ground.clock
    await create_timer(0.05, true).timeout
    check(is_equal_approx(weather.clock, paused_clock), "Rain must pause with the game")
    check(is_equal_approx(ground.clock, paused_ground_clock), "Ground splashes must pause with the game")
    paused = false
    await create_timer(0.05, true).timeout
    check(weather.clock > paused_clock, "Rain must resume with the game")
    check(ground.clock > paused_ground_clock, "Ground splashes must resume with the game")

func check_controls_ignore_mouse(node: Node) -> void:
    if node is Control:
        check(node.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Weather must not consume menu or gameplay input: " + str(node.name))
    for child in node.get_children():
        check_controls_ignore_mouse(child)

func check_iara_cycle(fight: Node) -> void:
    preload("res://iara_test_support.gd").prepare_fight(fight)
    freeze(fight)
    var health_before: int = fight.player.hp
    fight._physics_process(fight.state_timer + 0.01)
    check(fight.state == fight.State.PREPARING, "Rain must preserve Iara's preparation")
    fight._physics_process(fight.state_timer + 0.01)
    check(fight.state == fight.State.CASTING, "Rain must preserve Iara's spell travel")
    fight._physics_process(fight.CAST_SECONDS + 0.01)
    freeze(fight)
    check(fight.state == fight.State.SEDUCING and fight.player.seduction_source == fight.boss, "Rain must preserve the normal trance")
    check(fight.key_prompt.visible and fight.get_node("HUD/BossHealth").visible, "The trance keys and boss HUD must stay visible")
    for index in fight.RESISTANCE_REQUIRED:
        fight.register_resistance(-1 if index % 2 == 0 else 1)
        if fight.state == fight.State.SEDUCING:
            fight._physics_process(fight.RESISTANCE_COOLDOWN)
    check(fight.state == fight.State.FALLING, "The ordinary A/D resistance must still break Iara's trance")
    check(fight.player.hp == health_before, "Presentation changes must not damage the player")

func freeze(level: Node) -> void:
    level.set_process(false)
    level.set_physics_process(false)
    for actor in get_nodes_in_group("player") + get_nodes_in_group("enemy"):
        actor.set_physics_process(false)
