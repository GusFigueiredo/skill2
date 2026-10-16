extends SceneTree

const Progress := preload("res://scripts/CampaignProgress.gd")
const STAGE_PATH := "res://floresta5.tscn"
var failures := 0

func _initialize() -> void:
    call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error(message)

func run_checks() -> void:
    # Opening the scene saves a checkpoint. Never use the player's APPDATA.
    if not OS.get_environment("APPDATA").contains("jaguar-"):
        push_error("Use an isolated APPDATA directory named jaguar-* for this check")
        quit(1)
        return
    create_timer(100.0, true).timeout.connect(func():
        push_error("Jaguar checks timed out")
        quit(1)
    )
    for index in range(4):
        Progress.complete_stage(index)
    await open_forest()
    var level = current_scene
    freeze(level)
    var cats := jaguars(level)
    check(level.bushes.size() == 5, "The three forest sections must contain five recurring bushes")
    for bush in level.bushes:
        check(is_equal_approx(bush.position.y, 420.0), "All recurring bushes must sit along the upper edge of the playable ground")
    check(cats.size() == 2, "Exactly two of the five bushes must contain a jaguar")
    check(level.waves.size() == 3 and level.waves[0].size() == 4 and level.waves[1].size() == 3 and level.waves[2].size() == 5, "Jaguar encounters must preserve all existing forest enemies and three sections")
    check(level.CAVE_TRIGGER_X == 3700.0, "The earlier cave approach must remain at x3700")
    if cats.size() != 2:
        quit(1)
        return
    var first = cats[0]
    var last = cats[1]
    for cat in cats:
        check(is_instance_valid(cat.bush) and cat.position == cat.bush.position, "A concealed jaguar must originate in its actual upper-edge bush")
    check(level.waves[0].has(first) and level.waves[2].has(last), "Ambushes must be spread across the first and third sections")
    check(first.active and not last.active, "Future-section jaguars must not trigger prematurely")
    check_concealed(first)
    check_concealed(last)
    check_frames(first)
    await check_guaranteed_ambushes(level, first)
    # Even after the ordinary guards die, the concealed animal still gates its
    # section. The player must actually resolve the encounter.
    for enemy in level.waves[0]:
        if enemy != first:
            enemy.take_damage(enemy.hp)
    await process_frame
    level._process(0.0)
    check(not level.road_open and not level._section_is_clear(), "A hidden living jaguar must prevent the first road from opening")
    first.take_damage(100)
    check(first.hp == first.max_hp, "The hidden jaguar cannot be killed with invisible pre-ambush hits")
    var hero = level.player
    var normal_camera = hero.get_node("Camera2D")
    var original_zoom: Vector2 = normal_camera.zoom
    var original_rotation: float = hero.sprite.rotation
    var original_scale: Vector2 = hero.sprite.scale
    var actor_modes := {}
    for enemy in get_nodes_in_group("enemy"):
        if enemy != first:
            actor_modes[enemy.get_instance_id()] = enemy.process_mode
    var grapple = await trigger_ambush(level, first, 130.0)
    if not is_instance_valid(grapple):
        quit(1)
        return
    grapple.set_process(false)
    check(hero.control_locked and level.boss_intro_running, "The ground struggle must lock ordinary combat and protect its presentation")
    check(first.state == first.State.GRAPPLE, "A landed ambush must hand off to the ground struggle")
    for enemy in get_nodes_in_group("enemy"):
        if enemy != first:
            check(not enemy.can_process(), "Other enemies must freeze while the hero is pinned")
    advance_grapple(grapple, 2.0, "struggle")
    check(grapple.phase == "struggle", "The cinematic arrival must progress into the mash phase")
    check(grapple.prompt.visible, "The struggle must show the supplied K key")
    check(grapple.prompt.find_children("*", "TextureRect", true, false).size() == 1, "The QTE must show a single K icon")
    for removed_type in ["Label", "Panel", "PanelContainer", "ProgressBar", "TextureProgressBar"]:
        check(grapple.prompt.find_children("*", removed_type, true, false).is_empty(), "The minimal K prompt must not retain a " + removed_type + " card element")
    grapple.prompt.set_process(false)
    grapple.prompt._process(0.0)
    var normal_key_position: Vector2 = grapple.prompt.icon.position
    var normal_key_scale: Vector2 = grapple.prompt.icon.scale
    check(grapple.prompt.normal_texture.get_image().get_pixel(0, 0).a == 0.0 and grapple.prompt.pressed_texture.get_image().get_pixel(0, 0).a == 0.0, "Both supplied K variants must have a transparent exterior")
    var rejected_camera := camera_pose(grapple.camera)
    var wrong_key := InputEventKey.new()
    wrong_key.keycode = KEY_J
    wrong_key.physical_keycode = KEY_J
    wrong_key.pressed = true
    Input.parse_input_event(wrong_key)
    Input.flush_buffered_events()
    check(grapple.progress == 0.0, "Only K may advance the ground struggle")
    check(camera_pose(grapple.camera) == rejected_camera, "A wrong key must not trigger screen impact")
    var health_before: int = hero.hp
    hero.attack_cooldown_timer = 0.0
    hero.has_attacked = false
    hero._attack()
    hero._start_dodge(1.0)
    check(not hero.has_attacked and not hero.is_dodging, "K cannot punch or roll while it is used to resist the jaguar")

    # Feed actual engine input. Holding K, repeated press events without release,
    # OS keyboard echo, and inputs during pause must never count as new taps.
    set_k(false)
    var before_press_camera := camera_pose(grapple.camera)
    var before_press_clock: float = grapple.clock
    set_k(true)
    var after_press: float = grapple.progress
    check(after_press > 0.0, "A real K down event must increase resistance")
    check(grapple.prompt.icon.texture == grapple.prompt.pressed_texture, "A valid tap must visibly press the supplied K sprite")
    check(grapple.prompt.icon.position.y > normal_key_position.y + 1.0 and grapple.prompt.icon.scale.y < normal_key_scale.y, "Pressing K must lower and compress the icon")
    var pressed_key_position: Vector2 = grapple.prompt.icon.position
    var pressed_key_scale: Vector2 = grapple.prompt.icon.scale
    var pressed_camera := camera_pose(grapple.camera)
    check(is_equal_approx(grapple.clock, before_press_clock) and pressed_camera != before_press_camera, "A valid K tap must immediately kick the camera during the same input event, even with time frozen")
    set_k(true)
    set_k(true, true)
    check(camera_pose(grapple.camera) == pressed_camera and is_equal_approx(grapple.progress, after_press), "Holding K and OS echo must not create additional immediate impacts")
    advance_grapple(grapple, 0.35)
    check(grapple.progress <= after_press + 0.01, "Holding K and OS echo must not repeatedly advance resistance")
    set_k(false)
    grapple.prompt._process(0.35)
    check(grapple.prompt.icon.texture == grapple.prompt.normal_texture and grapple.prompt.icon.scale.y > pressed_key_scale.y, "Releasing K must restore the normal sprite and button height")
    check(grapple.prompt.icon.position.y < pressed_key_position.y, "Releasing K must return the icon from its depressed position")
    var idle_icon_position: Vector2 = grapple.prompt.icon.position
    var idle_icon_scale: Vector2 = grapple.prompt.icon.scale
    grapple.prompt._process(0.10)
    check(grapple.prompt.icon.position != idle_icon_position or grapple.prompt.icon.scale != idle_icon_scale, "An unpressed K icon must animate to invite another tap")
    grapple.prompt.set_process(true)
    grapple.set_process(true)
    paused = true
    var paused_elapsed: float = grapple.elapsed
    var paused_progress: float = grapple.progress
    var paused_camera: Vector2 = root.get_camera_2d().offset
    var paused_key_position: Vector2 = grapple.prompt.icon.position
    var paused_prompt_clock: float = grapple.prompt.clock
    set_k(true)
    set_k(false)
    for _frame in range(4):
        await process_frame
    check(is_equal_approx(grapple.elapsed, paused_elapsed) and is_equal_approx(grapple.progress, paused_progress), "Pause must freeze both QTE timer and input")
    check(root.get_camera_2d().offset == paused_camera, "Pause must freeze the frantic camera")
    check(grapple.prompt.icon.position == paused_key_position and is_equal_approx(grapple.prompt.clock, paused_prompt_clock), "Pause must freeze the animated K icon")
    paused = false
    grapple.prompt.set_process(false)
    grapple.set_process(false)
    var first_camera_position: Vector2 = root.get_camera_2d().offset
    advance_grapple(grapple, 0.13)
    check(root.get_camera_2d().offset.distance_to(first_camera_position) > 0.05, "The struggle must visibly shake its cinematic camera")
    var taps := 0
    while is_instance_valid(grapple) and grapple.phase == "struggle" and taps < 18:
        var before_tap_camera := camera_pose(grapple.camera)
        set_k(true)
        check(camera_pose(grapple.camera) != before_tap_camera, "Every accepted K tap must visibly kick the screen immediately")
        set_k(false)
        advance_grapple(grapple, 0.21)
        taps += 1
    check(taps <= 13 and grapple.phase in ["pushing", "return", "finished"], "A steady normal twelve-tap mash must expel the jaguar in about three seconds")
    check(hero.hp == health_before, "A successful resistance sequence must not damage the hero")
    advance_grapple(grapple, 5.0)
    await process_frame
    check(not is_instance_valid(level.active_jaguar_grapple), "Finishing the struggle must clear the active encounter reference")
    check(not hero.control_locked and not level.boss_intro_running, "Successful escape must return ordinary controls")
    check(root.get_camera_2d() == normal_camera and normal_camera.zoom == original_zoom, "Escape must restore the exact gameplay camera and zoom")
    check(is_equal_approx(hero.sprite.rotation, original_rotation) and hero.sprite.scale == original_scale, "The hero must leave the cinematic without rotated or stretched visuals")
    check(first.hp > 0 and first.ambush_used and not first.grappled, "Pushing the jaguar must start combat rather than kill it or replay the ambush")
    for enemy in get_nodes_in_group("enemy"):
        if actor_modes.has(enemy.get_instance_id()):
            check(enemy.process_mode == actor_modes[enemy.get_instance_id()], "The cinematic must restore every other enemy's original processing mode")
    freeze(level)
    await check_combat(level, first)

    # Clearing the first fight must open the route, then a retry beyond the hole
    # must preserve that victory rather than respawning its concealed animal.
    level._process(0.0)
    check(level.road_open, "Defeating the jaguar and normal guards must open the first route")
    hero.position = Vector2(level.SECOND_STAGE_GATE, 450)
    level._process(0.0)
    freeze(level)
    check(level.wave_index == 1 and level.checkpoint_id == "trecho_2", "The normal second-section checkpoint must still activate")
    level = await restart(level)
    check(jaguars(level).size() == 1 and level.wave_index == 1, "Checkpoint retry must keep the first jaguar defeated")
    await defeat_wave(level, 1)
    level._process(0.0)
    level.player.position = Vector2(level.THIRD_STAGE_GATE, 450)
    level._process(0.0)
    freeze(level)
    last = jaguars(level)[0]
    check(last.active and not last.ambush_used, "The third section must activate its own fresh ambush")
    for enemy in level.waves[2]:
        if enemy != last:
            enemy.take_damage(enemy.hp)
    await process_frame
    level.player.position = Vector2(level.CAVE_TRIGGER_X, 450)
    level._process(0.0)
    check(not level.cave_ready and not level.cave_entering, "A hidden third-section jaguar must block the cave even after all guards die")
    grapple = await trigger_ambush(level, last)
    grapple.set_process(false)
    advance_grapple(grapple, 2.0, "struggle")
    var timeout_health: int = level.player.hp
    advance_grapple(grapple, 14.0)
    await process_frame
    check(level.player.hp == timeout_health - 2 and level.player.hp > 0, "Ignoring K must cause exactly two HP of normal damage, allowing combat to continue")
    check(not is_instance_valid(level.active_jaguar_grapple) and not level.player.control_locked and not level.boss_intro_running, "A failed resistance must also restore camera, controls and ordinary enemies")
    check(root.get_camera_2d() == level.player.get_node("Camera2D"), "The failure path must return to the gameplay camera")
    level = await restart(level)
    check(level.wave_index == 2 and jaguars(level).size() == 1, "A retry after failure must return to section three with only its own jaguar")
    freeze(level)
    last = jaguars(level)[0]
    level.player.hp = 1
    grapple = await trigger_ambush(level, last)
    grapple.set_process(false)
    advance_grapple(grapple, 2.0, "struggle")
    advance_grapple(grapple, 14.0)
    await process_frame
    check(level.player.hp == 0 and level.death_screen.visible, "Losing the struggle at low health must use the normal visible death flow")
    check(not level.player.control_locked and not is_instance_valid(level.active_jaguar_grapple), "A lethal timeout must release the QTE before death and retry")
    level = await restart(level)
    check(level.player.hp == level.player.max_hp and not level.player.control_locked, "Retrying a lethal struggle must restore full health and controls")
    last = jaguars(level)[0]
    grapple = await trigger_ambush(level, last)
    grapple.set_process(false)
    advance_grapple(grapple, 1.5, "struggle")
    level = await restart(level)
    check(not level.player.control_locked and not level.boss_intro_running and not is_instance_valid(level.active_jaguar_grapple), "Retrying during an active ground struggle must leave no stuck locks or camera")
    check(root.get_camera_2d() == level.player.get_node("Camera2D"), "Retrying during QTE must not retain the freed cinematic camera")

    set_k(false)
    change_scene_to_file("res://main.tscn")
    await process_frame
    await process_frame
    check(jaguars(current_scene).is_empty() and current_scene.get_script().resource_path != "res://scripts/CucaForest.gd", "Jaguar mechanics must stay exclusive to phase five")
    if failures == 0:
        print("PASS: five upper-edge bushes/two gated jaguars; guaranteed smooth first pounce against moving/jumping/dodging targets with invalid-state guards; single animated/depressed K without a card; same-event screen impact, real K down/up, holding/echo/pause; success/failure/retry cleanup; avoidable normal paw/bite/leap and real player kill; checkpoint persistence and unchanged cave approach")
    quit(0 if failures == 0 else 1)

func camera_pose(camera: Camera2D) -> Array:
    return [camera.offset, camera.rotation, camera.zoom]

func jaguars(level: Node) -> Array:
    var result := []
    for enemy in get_nodes_in_group("enemy"):
        if enemy.get_parent() == level and enemy.has_method("configure_ambush"):
            result.append(enemy)
    result.sort_custom(func(a, b): return a.position.x < b.position.x)
    return result

func check_concealed(cat: Node) -> void:
    check(not cat.visible and cat.collision_layer == 0 and cat.collision_mask == 0 and cat.get_node("HurtArea").collision_layer == 0, "Concealed jaguars must be invisible and non-solid/non-hittable")

func check_frames(cat: Node) -> void:
    var frames: SpriteFrames = cat.get_node("Sprite").sprite_frames
    var counts := {"bush_rustle": 4, "bush_reveal": 3, "emerge": 5, "leap": 2, "idle": 3, "run": 3, "paw": 3, "bite": 4, "death": 4, "struggle": 1}
    for animation_name in counts:
        check(frames.has_animation(animation_name), "Missing supplied jaguar animation: " + animation_name)
        if frames.has_animation(animation_name):
            check(frames.get_frame_count(animation_name) == counts[animation_name], "The jaguar must retain every pose in " + animation_name)
            for index in frames.get_frame_count(animation_name):
                var texture: Texture2D = frames.get_frame_texture(animation_name, index)
                check(texture != null and texture.get_width() > 0 and texture.get_height() > 0, "Jaguar frames must remain nonempty")
                if texture is AtlasTexture:
                    check(texture.margin.position.x >= 0.0 and texture.margin.position.y >= 0.0, "A shared animation canvas must fit the entire supplied " + animation_name + " pose")

func trigger_ambush(level: Node, cat: Node, vertical_offset: float = 0.0) -> Node:
    var hero = level.player
    hero.position = cat.position + Vector2(-175, vertical_offset)
    hero.jump_height = 0.0
    hero.jump_speed = 0.0
    hero._end_dodge()
    hero.damage_cooldown = 0.0
    cat._physics_process(0.01)
    check(cat.state == cat.State.RUSTLE, "A grounded nearby player must rustle the occupied bush")
    check(cat.collision_layer == 0 and cat.get_node("HurtArea").collision_layer == 0, "Rustling must not enable invisible contact damage")
    for _frame in range(ceili(cat.RUSTLE_SECONDS * 60.0) + 1):
        cat._physics_process(1.0 / 60.0)
    check(cat.state == cat.State.AMBUSH, "The rustling reveal must become an ambush leap")
    var peak := 0.0
    var previous: Vector2 = cat.position
    for _frame in range(48):
        if cat.state != cat.State.AMBUSH:
            break
        cat._physics_process(1.0 / 60.0)
        peak = maxf(peak, -cat.get_node("Sprite").position.y)
        check(cat.position.distance_to(previous) < 30.0, "The ambush leap must move continuously without teleporting")
        previous = cat.position
    check(peak > 45.0, "The ambush must show a visible airborne arc")
    check(is_instance_valid(level.active_jaguar_grapple), "A landed ambush must start the K ground struggle")
    return level.active_jaguar_grapple

func prepare_fresh_ambush(level: Node, cat: Node) -> void:
    var hero = level.player
    hero.hp = hero.max_hp
    hero.control_locked = false
    hero.is_falling = false
    hero.jump_height = 0.0
    hero.jump_speed = 0.0
    hero._end_dodge()
    hero.dodge_protected_frame = -1
    hero.damage_cooldown = 0.0
    hero.position = cat.bush.position + Vector2(-175.0, 130.0)
    cat.configure_ambush(cat.bush.position, cat.bush)
    cat.set_encounter_active(true)
    cat.set_physics_process(false)
    cat._physics_process(0.01)
    check(cat.state == cat.State.RUSTLE, "Every first-pounce scenario must begin with the actual bush reveal")
    for _frame in range(ceili(cat.RUSTLE_SECONDS * 60.0) + 1):
        cat._physics_process(1.0 / 60.0)
    check(cat.state == cat.State.AMBUSH, "The actual reveal must commit its first pounce")

func check_guaranteed_ambushes(level: Node, cat: Node) -> void:
    var hero = level.player
    var scenarios := ["running_away", "fast_retreat", "changing_lane", "jump", "dodge"]
    for scenario in scenarios:
        prepare_fresh_ambush(level, cat)
        var launch_target: Vector2 = hero.global_position
        var previous: Vector2 = cat.global_position
        var live_evasion := false
        var peak := 0.0
        for frame in range(48):
            if cat.state != cat.State.AMBUSH:
                break
            var delta := 1.0 / 60.0
            if scenario == "running_away":
                hero.global_position += Vector2(-hero.speed, 0) * delta
            elif scenario == "fast_retreat":
                # More than the former 330px aim limit, spread over real ticks.
                hero.global_position += Vector2(-545.0, 0) * delta
            elif scenario == "changing_lane":
                hero.global_position += Vector2(hero.speed, -180.0) * delta
            elif scenario == "jump":
                if frame == 26:
                    hero.jump_speed = -hero.jump_velocity
                if frame >= 26:
                    hero._physics_process(delta)
                    live_evasion = hero.jump_height > 30.0
            elif scenario == "dodge":
                if frame == 31:
                    hero.can_dodge = true
                    hero._start_dodge(-1.0)
                if frame >= 31:
                    hero._physics_process(delta)
                    live_evasion = hero.is_dodge_invulnerable()
            var hp_before: int = cat.hp
            cat.take_damage(cat.max_hp + 1)
            check(cat.hp == hp_before and cat.get_node("HurtArea").collision_layer == 0, "The first pounce must reach the ground struggle even if the player attacks during " + scenario)
            cat._physics_process(delta)
            peak = maxf(peak, cat.leap_height)
            check(cat.global_position.distance_to(previous) < 40.0, "Tracking the player's " + scenario + " must keep the first pounce continuous without a final teleport")
            previous = cat.global_position
        check(peak > 45.0, "Tracking " + scenario + " must retain the visible leap arc")
        if scenario in ["running_away", "fast_retreat", "changing_lane"]:
            check(hero.global_position.distance_to(launch_target) > 120.0, "The " + scenario + " target must move substantially after launch")
        else:
            check(live_evasion, "The " + scenario + " must still be active on the contact tick")
        check(cat.state == cat.State.GRAPPLE and is_instance_valid(level.active_jaguar_grapple), "The first pounce must always start the K struggle against " + scenario)
        check(cat.global_position.distance_to(hero.global_position) < 1.0, "The first pounce must actually land on its moving target during " + scenario)
        check(hero.jump_height == 0.0 and hero.jump_speed == 0.0 and not hero.is_dodging, "Starting the struggle must clear jump and dodge state")
        if is_instance_valid(level.active_jaguar_grapple):
            level.active_jaguar_grapple.abort()
            await process_frame
        freeze(level)
        check(not hero.control_locked and not level.boss_intro_running, "The " + scenario + " scenario must cleanly release the struggle")

    for blocked_state in ["dead", "falling", "other_control", "finished", "cave"]:
        prepare_fresh_ambush(level, cat)
        match blocked_state:
            "dead": hero.hp = 0
            "falling": hero.is_falling = true
            "other_control": hero.control_locked = true
            "finished": level.finished = true
            "cave": level.cave_entering = true
        for _frame in range(48):
            cat._physics_process(1.0 / 60.0)
        check(not is_instance_valid(level.active_jaguar_grapple) and cat.state != cat.State.GRAPPLE, "A committed first pounce must not steal the " + blocked_state + " flow")
        hero.hp = hero.max_hp
        hero.is_falling = false
        hero.control_locked = false
        level.finished = false
        level.cave_entering = false
    hero._end_dodge()
    hero.dodge_protected_frame = -1
    hero.jump_height = 0.0
    hero.jump_speed = 0.0
    hero.position = level.STAGE_START
    cat.configure_ambush(cat.bush.position, cat.bush)
    cat.set_encounter_active(true)
    freeze(level)

func advance_grapple(grapple: Node, seconds: float, stop_phase: String = "") -> void:
    for _step in range(ceili(seconds * 60.0)):
        if not is_instance_valid(grapple) or grapple.is_queued_for_deletion() or grapple.phase == "finished" or (not stop_phase.is_empty() and grapple.phase == stop_phase):
            return
        grapple._process(1.0 / 60.0)

func check_combat(level: Node, cat: Node) -> void:
    var hero = level.player
    hero.hp = hero.max_hp
    for index in range(3):
        var kind: String = ["paw", "bite", "leap"][index]
        prepare_attack(level, cat, index)
        var health: int = hero.hp
        var tell: float = cat.state_duration
        check(cat.state == cat.State.TELL and cat.attack_kind == kind and tell >= 0.4, "Each " + kind + " must announce itself before impact")
        cat._physics_process(tell * 0.5)
        check(cat.state == cat.State.TELL and hero.hp == health, "The " + kind + " warning must allow time to react without damage")
        cat._physics_process(tell * 0.5 + 0.01)
        if kind == "leap":
            check(cat.state == cat.State.LEAP, "The combat leap must leave the ground after its warning")
            cat._physics_process(0.3)
            check(cat.leap_height > 35.0, "A combat leap must keep its airborne arc")
            cat._physics_process(0.36)
        else:
            check(cat.state == cat.State.STRIKE and cat.visual.animation == kind, "The " + kind + " attack must use its own animation")
            cat._physics_process(cat.state_duration * 0.4)
        check(hero.hp == health - cat.attack_damage, "A correctly aimed " + kind + " must hit the hero once")
        hero.damage_cooldown = 0.0
        cat._physics_process(0.035)
        check(hero.hp == health - cat.attack_damage, "Remaining " + kind + " frames must not apply a second hit")

        prepare_attack(level, cat, index)
        health = hero.hp
        hero.can_dodge = true
        hero._start_dodge(-1.0)
        cat._physics_process(cat.state_duration + 0.01)
        cat._physics_process(0.7)
        check(hero.hp == health, "A real dodge must protect against the " + kind + " attack")
        hero._end_dodge()

    # Tracking is exclusive to the first bush pounce: ordinary combat leaps
    # commit to a landing point and allow the player to move out of the way.
    prepare_attack(level, cat, 2)
    cat._physics_process(cat.state_duration + 0.01)
    check(cat.state == cat.State.LEAP, "The avoidable leap scenario must reach a normal combat leap")
    var fixed_target: Vector2 = cat.leap_target
    var leap_health: int = hero.hp
    for _frame in range(42):
        hero.global_position += Vector2(-hero.speed, 0) / 60.0
        cat._physics_process(1.0 / 60.0)
        check(cat.leap_target == fixed_target, "An ordinary combat leap must keep its original landing point")
    check(hero.hp == leap_health and not is_instance_valid(level.active_jaguar_grapple), "Moving away after launch must avoid the ordinary combat leap without a new K struggle")

    # An actual Player._attack physics shape query must reach the animal's
    # HurtArea. Direct take_damage would miss a broken combat collision layer.
    cat.position = Vector2(800, 420)
    cat._change_state(cat.State.RECOVERY, 999.0)
    cat.recovery_push = Vector2.ZERO
    cat._set_body_enabled(true)
    hero.position = Vector2(735, 420)
    hero.facing = 1
    hero.attack_vertical = 0
    var expected_hp: int = cat.hp
    for _hit in range(cat.hp):
        await physics_frame
        hero.attack_cooldown_timer = 0.0
        hero._attack()
        expected_hp -= hero.attack_damage
        check(not is_instance_valid(cat) or cat.hp == maxi(0, expected_hp), "A real player punch must damage the exposed jaguar")
        if not is_instance_valid(cat) or cat.hp <= 0:
            break
    await process_frame
    check(not is_instance_valid(cat) or cat.hp == 0, "Player attacks must be able to defeat the post-grapple jaguar")

func prepare_attack(level: Node, cat: Node, index: int) -> void:
    var hero = level.player
    cat.position = Vector2(800, 420)
    hero.position = Vector2(890, 420)
    hero.damage_cooldown = 0.0
    hero.jump_height = 0.0
    hero.jump_speed = 0.0
    hero._end_dodge()
    cat.recovery_push = Vector2.ZERO
    cat.attack_cooldown_timer = 0.0
    cat.attack_number = index
    cat._change_state(cat.State.PURSUE)
    cat._physics_process(0.001)

func freeze(level: Node) -> void:
    level.set_process(false)
    level.set_physics_process(false)
    for actor in get_nodes_in_group("player") + get_nodes_in_group("enemy"):
        if actor.get("spawn_tween") != null and actor.spawn_tween.is_valid():
            actor.spawn_tween.custom_step(3.0)
        actor.set_physics_process(false)

func open_forest() -> void:
    change_scene_to_file(STAGE_PATH)
    await process_frame
    await process_frame

func defeat_wave(level: Node, index: int) -> void:
    for enemy in level.waves[index]:
        if is_instance_valid(enemy) and enemy.hp > 0:
            if enemy.has_method("finish_grapple"):
                enemy.finish_grapple(true)
            enemy.take_damage(enemy.hp)
    await process_frame

func restart(level: Node) -> Node:
    paused = false
    level._reset_scene()
    while root.get_node("SceneTransition").busy:
        await process_frame
    await process_frame
    freeze(current_scene)
    return current_scene

func set_k(pressed: bool, echo: bool = false) -> void:
    var event := InputEventKey.new()
    event.keycode = KEY_K
    event.physical_keycode = KEY_K
    event.pressed = pressed
    event.echo = echo
    Input.parse_input_event(event)
    Input.flush_buffered_events()

