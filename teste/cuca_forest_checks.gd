extends SceneTree

const Progress = preload("res://scripts/CampaignProgress.gd")
const STAGE_PATH := "res://floresta5.tscn"
var failures := 0

func _initialize() -> void:
    call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error(message)

func run_checks() -> void:
    # These checks exercise real saves and must never touch the player's APPDATA.
    if not OS.get_environment("APPDATA").contains("stage5-"):
        push_error("Use an isolated APPDATA directory named stage5-* for this check")
        quit(1)
        return
    create_timer(80.0, true).timeout.connect(func():
        push_error("Cuca forest checks timed out")
        quit(1)
    )
    check(Progress.completed_stages() == 0 and Progress.checkpoint().is_empty(), "Checks require a fresh isolated campaign")
    for index in range(4):
        Progress.complete_stage(index)
    check(Progress.stage_path(4) == STAGE_PATH and Progress.is_available(4), "Finishing Iara must unlock the forest as phase five")
    await open_scene()
    var level = current_scene
    freeze(level)
    check(level.stage_index == 4 and level.player.position == level.STAGE_START, "Phase five must start in the forest")
    check(level.waves.size() == 3 and level.waves[0].size() == 4 and level.waves[1].size() == 3 and level.waves[2].size() == 5, "The forest must retain three separate sections, with one additional jaguar in the first and third")
    check(level.pits.size() == 1 and level.pits[0].end.x < level.SECOND_STAGE_GATE, "The only hole must lie between sections one and two")
    check(not level.boss.visible and not level.get_node("HUD/BossHealth").visible, "Cuca must not appear as a boss in the forest")
    check(not level.finished and not level.cave_ready and not level.cave_entering, "A fresh forest must not enter the cave or finish automatically")
    check_active_wave(level, 0)
    level.player.position.x = level.THIRD_STAGE_GATE
    level._process(0.0)
    check(level.wave_index == 0 and not level.road_open, "Walking ahead cannot skip living enemies in the first section")
    level.player.position = level.STAGE_START

    # A grounded step into the hole uses the normal fall/death presentation.
    level.player.position = level.pits[0].get_center()
    level.check_player_floor(level.player.position)
    check(level.player.is_falling and level.player.hp == 0 and level.death_screen.visible, "Walking into the hole must cause a visible death")
    level = await restart(level)
    check(level.wave_index == 0 and level.checkpoint_id == "start" and level.player.position == level.STAGE_START, "A fall before section two must restart the first checkpoint")
    check(level.player.hp == level.player.max_hp and not level.player.is_falling, "Restart must clear falling state and restore all health")

    await defeat_wave(level, 0)
    level._process(0.0)
    check(level.road_open and level.wave_index == 0, "Clearing section one must open the road without starting section two remotely")
    check_active_wave(level, -1)

    # A real grounded roll must fall; its movement sweep cannot bypass the pit.
    level.player.position = Vector2(level.pits[0].position.x - 35.0, 450.0)
    level.player.facing = 1
    level.player._start_dodge(1.0)
    level.player.set_physics_process(true)
    for _frame in range(25):
        await physics_frame
        if level.player.is_falling:
            break
    level.player.set_physics_process(false)
    check(level.player.is_falling and level.player.hp == 0, "Rolling into the gap must not grant immunity to falling")
    level = await restart(level)
    await defeat_wave(level, 0)
    level._process(0.0)

    # Cross the actual gap with ordinary right movement and one jump input.
    level.player.position = Vector2(level.pits[0].position.x - 48.0, 450.0)
    Input.action_press("ui_right")
    set_space(true)
    level.player.set_physics_process(true)
    var peak_height := 0.0
    for frame in range(55):
        await physics_frame
        peak_height = maxf(peak_height, level.player.jump_height)
        if frame == 1:
            set_space(false)
    Input.action_release("ui_right")
    set_space(false)
    level.player.set_physics_process(false)
    check(peak_height > 50.0 and level.player.has_jumped, "Normal jump input must produce a visible airborne arc")
    check(level.player.position.x > level.pits[0].end.x + level.PIT_DEATH_MARGIN and not level.player.is_falling and level.player.hp > 0, "The hole must be passable with one ordinary running jump")
    check(is_zero_approx(level.player.jump_height), "The player must land safely after crossing the gap")

    level.player.position = Vector2(level.SECOND_STAGE_GATE - 1.0, 450.0)
    level._process(0.0)
    check(level.wave_index == 0, "The second encounter must wait until its entrance is reached")
    level.player.position.x = level.SECOND_STAGE_GATE
    level._process(0.0)
    freeze(level)
    check(level.wave_index == 1 and level.checkpoint_id == "trecho_2", "Entering section two must save its checkpoint")
    check_active_wave(level, 1)
    level = await restart(level)
    check(level.wave_index == 1 and level.checkpoint_id == "trecho_2", "Death in section two must stay in phase five and section two")
    check(level.player.position.x > level.pits[0].end.x + 28.0 and level.player.hp == level.player.max_hp, "The second checkpoint must respawn safely beyond the hole with full health")
    check(alive_count(level.waves[0]) == 0, "The first section must stay defeated after a second-section retry")
    check_active_wave(level, 1)
    level.player.position.x = level.THIRD_STAGE_GATE
    level._process(0.0)
    check(level.wave_index == 1 and not level.road_open, "Living second-section enemies must block the third encounter")
    level.player.position.x = level.SECOND_STAGE_GATE + 200.0
    await defeat_wave(level, 1)
    level._process(0.0)
    check(level.wave_index == 1 and level.road_open, "Defeating section two must open the continuous path to section three")
    for x in range(int(level.SECOND_STAGE_GATE), int(level.STAGE_LENGTH - 60.0), 35):
        level.player.position = Vector2(x, 450.0)
        level.check_player_floor(level.player.position)
        check(not level.player.is_falling, "There must be no further holes between section two and the cave")
    level.player.position = Vector2(level.THIRD_STAGE_GATE - 1.0, 450.0)
    level._process(0.0)
    check(level.wave_index == 1, "The third encounter must wait until its entrance is reached")
    level.player.position.x = level.THIRD_STAGE_GATE
    level._process(0.0)
    freeze(level)
    check(level.wave_index == 2 and level.checkpoint_id == "trecho_3", "Entering section three must save a checkpoint")
    check_active_wave(level, 2)
    level = await restart(level)
    check(level.wave_index == 2 and level.checkpoint_id == "trecho_3" and level.player.hp == level.player.max_hp, "Third-section retry must restore the encounter with full health")
    check(alive_count(level.waves[0]) + alive_count(level.waves[1]) == 0, "Third-section retry must preserve both completed sections")
    check_active_wave(level, 2)

    # The exit is physical: the last enemy blocks it, then walking is required.
    var final_enemy = level.waves[2].back()
    for enemy in level.waves[2]:
        if enemy != final_enemy:
            enemy.take_damage(enemy.hp)
    await process_frame
    level.player.position = Vector2(level.CAVE_TRIGGER_X, level.CAVE_DOOR.y)
    level._process(0.0)
    check(not level.cave_ready and not level.cave_entering and not level.finished, "The last surviving enemy must block the cave even if the player reaches its doorway")
    level.player.position = Vector2(level.THIRD_STAGE_GATE + 250.0, 450.0)
    if final_enemy.has_method("finish_grapple"):
        final_enemy.finish_grapple(true)
    final_enemy.take_damage(final_enemy.hp)
    await process_frame
    level._process(0.0)
    check(level.cave_ready and not level.cave_entering and not level.finished, "The final kill must open the cave without automatically ending the phase")
    check(Progress.completed_stages() == 4, "Clearing combat alone must not mark phase five complete")
    check(level.CAVE_TRIGGER_X == 3700.0 and level.CAVE_CHECKPOINT_X < level.CAVE_TRIGGER_X, "The screenshot's forest approach must start cave entry before the rocks, after a playable checkpoint")
    level.player.position.x = level.CAVE_CHECKPOINT_X + 5.0
    level._process(0.0)
    check(level.checkpoint_id == "caverna" and Progress.checkpoint().get("id") == "caverna", "Approaching the cleared cave must save its own checkpoint")
    level = await restart(level)
    check(level.checkpoint_id == "caverna" and level.cave_ready and alive_count(level.waves[2]) == 0, "Cave checkpoint must preserve all three completed fights")
    check(not level.cave_entering and not level.finished and level.player.hp == level.player.max_hp, "Cave retry must remain playable before entering the doorway")
    check(level.player.position.x < level.CAVE_TRIGGER_X, "The cave checkpoint must leave room to move before the cutscene")
    # Saves from the old doorway checkpoint must also resume before the new trigger.
    Progress.save_checkpoint(4, "caverna", Vector2(4240.0, 450.0))
    level = await restart(level)
    check(level.player.position.x <= level.CAVE_TRIGGER_X - 24.0 and not level.cave_entering, "An older cave save must be clamped behind the earlier entrance trigger")

    level.player.take_damage(1)
    level._update_hud()
    check(level.health_bar.value == level.player.hp and level.health_bar.max_value == level.player.max_hp, "The forest must retain the shared health HUD")
    var menu = level.get_node("PauseMenu")
    menu._set_paused(true)
    check(paused and menu.panel.visible, "The phase must open the normal pause menu")
    menu._start_or_resume()
    check(not paused and not menu.panel.visible, "Continue must resume phase five")
    level.player.position = Vector2(level.CAVE_TRIGGER_X - 1.0, 450.0)
    level._process(0.0)
    check(not level.cave_entering, "The cave must not start entry one pixel before the forest approach")
    level.player.position = Vector2(level.CAVE_TRIGGER_X, 339.0)
    level._process(0.0)
    check(not level.cave_entering, "Cave entry must not start outside the upper playable path")
    level.player.position.y = 561.0
    level._process(0.0)
    check(not level.cave_entering, "Cave entry must not start outside the lower playable path")
    level.player.position.y = 450.0
    level.player.jump_height = 25.0
    level._process(0.0)
    check(not level.cave_entering, "At the approach threshold cave entry must wait until the player lands")
    level.player.jump_height = 0.0
    level._process(0.0)
    check(level.cave_entering and not level.get_node("HUD").visible and not level.player.is_physics_processing(), "Landing at x3700 must start cave entry, lock input and hide the combat HUD")
    var entry_start: Vector2 = level.player.position
    await create_timer(0.25, true).timeout
    check(level.player.position.x > entry_start.x and level.player.position.distance_to(entry_start) < 85.0, "The earlier entrance must start with a normal walking pace, without teleporting across the approach")
    level.cave_entry_tween.pause()
    level = await restart(level)
    check(not level.cave_entering and level.player.position.x < level.CAVE_TRIGGER_X, "Retrying during the longer entry must still restore a playable cave checkpoint")

    # Reproduce the user's screenshot: the hero is still well left of the rocks.
    level.player.position = Vector2(3730.0, 480.0)
    var normal_camera := level.player.get_node("Camera2D") as Camera2D
    normal_camera.reset_smoothing()
    normal_camera.force_update_scroll()
    var original_center := normal_camera.get_screen_center_position()
    level._process(0.0)
    check(level.cave_entering, "The position shown in the screenshot must already activate the cave cutscene")
    check(level.cave_camera.global_position.distance_to(original_center) < 1.0, "The entrance camera must begin at the existing gameplay framing without jumping")
    var entry_health: int = level.player.hp
    var last_position: Vector2 = level.player.position
    var last_camera_position: Vector2 = level.cave_camera.global_position
    var crossed_boulders := false
    var reached_door := false
    var exit_visual := level.player.get_node("Sprite") as AnimatedSprite2D
    while current_scene == level and not root.get_node("SceneTransition").busy:
        await process_frame
        if not is_instance_valid(level):
            break
        var next_position: Vector2 = level.player.position
        check(next_position.x >= last_position.x - 0.1, "The approach must never walk the hero backward")
        check(next_position.distance_to(last_position) < 40.0, "The longer entrance must move continuously between rendered frames")
        check(level.cave_camera.global_position.distance_to(last_camera_position) < 40.0, "The entrance camera must pan continuously toward the cave")
        if next_position.x >= 3980.0 and next_position.x <= 4150.0:
            crossed_boulders = true
            check(next_position.y >= 520.0, "The entrance must follow the dirt path below the left boulders")
        if next_position.distance_to(level.CAVE_DOOR) < 1.0:
            reached_door = true
            check(level.cave_fade.color.a < 0.1 or exit_visual.modulate.a < 0.1 or level.player.modulate.a < 0.1, "The hero must reach the opening before the scene fades to black")
        if level.cave_fade.color.a > 0.1:
            check(reached_door, "The whole scene may only fade after the hero has walked into the opening")
        last_position = next_position
        last_camera_position = level.cave_camera.global_position
    check(crossed_boulders and reached_door, "The cutscene must show the complete approach around the rocks and into the cave")
    check(level.player.hp == entry_health, "The entry cutscene must preserve the hero's health")
    while current_scene.scene_file_path == STAGE_PATH or root.get_node("SceneTransition").busy:
        await process_frame
    check(current_scene.scene_file_path == "res://caverna6.tscn" and not paused, "Entering the cave must continue directly into phase six")
    check(Progress.completed_stages() == 5 and Progress.is_available(5), "Entering the cave must complete phase five and unlock phase six")
    check(Progress.checkpoint().get("stage", -1) == 5 and Progress.checkpoint().get("id", "") == "start", "The forest checkpoint must be replaced by the new cave's starting checkpoint")
    if failures == 0:
        print("PASS: phase five, three gated encounters, real jump and fatal ground roll, safe retries including legacy cave saves, shared HUD/pause and grounded early cave entry with a continuous walk around the boulders")
    quit(0 if failures == 0 else 1)

func open_scene() -> void:
    paused = false
    change_scene_to_file(STAGE_PATH)
    await process_frame
    await process_frame

func freeze(level: Node) -> void:
    level.set_process(false)
    level.set_physics_process(false)
    for actor in get_nodes_in_group("player") + get_nodes_in_group("enemy"):
        if actor.get("spawn_tween") != null and actor.spawn_tween.is_valid():
            actor.spawn_tween.custom_step(3.0)
        actor.set_physics_process(false)

func check_active_wave(level: Node, expected_index: int) -> void:
    freeze(level)
    for index in level.waves.size():
        for enemy in level.waves[index]:
            if is_instance_valid(enemy) and enemy.hp > 0:
                if enemy.has_method("set_encounter_active"):
                    check(enemy.active == (index == expected_index), "Only the current section's jaguar may watch for an ambush")
                    check(not enemy.visible, "An untriggered jaguar must remain concealed in its bush")
                else:
                    check(enemy.visible == (index == expected_index), "Only the current section's living enemies may be visible")

func alive_count(wave: Array) -> int:
    var count := 0
    for enemy in wave:
        if is_instance_valid(enemy) and enemy.hp > 0:
            count += 1
    return count

func defeat_wave(level: Node, index: int) -> void:
    for enemy in level.waves[index]:
        if is_instance_valid(enemy) and enemy.hp > 0:
            # Reveal ambushers before the fixture clears a wave; hidden animals
            # correctly reject ordinary combat damage before their encounter.
            if enemy.has_method("finish_grapple"):
                enemy.finish_grapple(true)
            enemy.take_damage(enemy.hp)
    await process_frame

func restart(level: Node) -> Node:
    if level.player.hp > 0:
        level.player.damage_cooldown = 0.0
        level.player.take_damage(100)
    level._reset_scene()
    while root.get_node("SceneTransition").busy:
        await process_frame
    await process_frame
    check(current_scene.scene_file_path == STAGE_PATH and not paused, "Checkpoint retry must keep phase five and resume the game")
    freeze(current_scene)
    return current_scene

func set_space(pressed: bool) -> void:
    var event := InputEventKey.new()
    event.keycode = KEY_SPACE
    event.physical_keycode = KEY_SPACE
    event.pressed = pressed
    Input.parse_input_event(event)
    Input.flush_buffered_events()
