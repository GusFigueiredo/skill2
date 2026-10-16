extends SceneTree

const Progress = preload("res://scripts/CampaignProgress.gd")
const STAGE_PATH := "res://caverna6.tscn"
var failures := 0

func _initialize() -> void:
    call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error(message)

func run_checks() -> void:
    # Every scene writes checkpoints. A fresh task-specific APPDATA protects saves.
    if not OS.get_environment("APPDATA").contains("cave6-"):
        push_error("Use a fresh isolated APPDATA directory containing cave6- for cave checks")
        quit(1)
        return
    create_timer(100.0, true).timeout.connect(func():
        push_error("Cuca cave checks timed out")
        quit(1)
    )
    check(Progress.completed_stages() == 0, "Checks require a fresh isolated campaign")
    check(Progress.stage_path(5) == STAGE_PATH and not Progress.is_available(5), "The implemented cave must remain locked before its predecessors")
    for index in range(5):
        Progress.complete_stage(index)
    check(Progress.is_available(5) and not Progress.is_available(6), "Finishing the forest must unlock only phase six")
    await open_scene()
    var level = current_scene
    freeze(level)
    check(level.stage_index == 5 and level.player.position == level.STAGE_START, "The cave must be phase six and start at its entrance")
    check(level.waves.size() == 3 and level.waves[0].size() == 3 and level.waves[1].size() == 3 and level.waves[2].size() == 4, "The cave must have three separate encounters")
    check(level.pits.size() == 1 and level.pits[0] == Rect2(2700, 325, 110, 255), "The only hole must be between the second and third sections")
    check(not level.boss.visible and not level.get_node("HUD/BossHealth").visible, "Exploration must keep the future laboratory encounter hidden until its entrance")
    check(level.tutorial.step == level.tutorial.Step.COMPLETE and not level.tutorial.visible, "The cave must not repeat the introductory tutorial")
    check_active_wave(level, 0)
    await check_scenery(level)
    level.player.position.x = level.THIRD_STAGE_GATE
    level._process(0.0)
    check(level.wave_index == 0 and not level.road_open, "The first encounter must block progress while enemies survive")
    level.player.position = level.STAGE_START
    for x in range(200, int(level.SECOND_STAGE_GATE), 35):
        level.player.position = Vector2(x, 450)
        level.check_player_floor(level.player.position)
        check(not level.player.is_falling, "The first-to-second route must not contain a hole")
    await defeat_wave(level, 0)
    level._process(0.0)
    check(level.road_open and level.wave_index == 0, "Clearing section one must open the road without starting the next fight remotely")
    level.player.position = Vector2(level.SECOND_STAGE_GATE - 1.0, 450)
    level._process(0.0)
    check(level.wave_index == 0, "Section two must wait until its gate")
    level.player.position.x += 1.0
    level._process(0.0)
    freeze(level)
    check(level.wave_index == 1 and level.checkpoint_id == "trecho_2", "Entering section two must save its own checkpoint")
    check_active_wave(level, 1)
    level = await restart(level)
    check(level.wave_index == 1 and level.checkpoint_id == "trecho_2" and alive_count(level.waves[0]) == 0, "A retry must retain the completed first encounter")
    check(level.player.hp == level.player.max_hp and level.player.position.x < level.pits[0].position.x, "Section-two retry must restore full health before the gap")
    level.player.position.x = level.THIRD_STAGE_GATE
    level._process(0.0)
    check(level.wave_index == 1 and not level.road_open, "Living section-two enemies must block the third encounter")
    level.player.position = Vector2(level.SECOND_STAGE_GATE + 200.0, 450)
    await defeat_wave(level, 1)
    level._process(0.0)
    check(level.road_open and level.wave_index == 1, "Clearing section two must open the route to the gap")

    level.player.position = level.pits[0].get_center()
    level.check_player_floor(level.player.position)
    check(level.player.is_falling and level.player.hp == 0 and level.death_screen.visible, "Walking into the actual gap must show the normal fall and death")
    level = await restart(level)
    check(level.wave_index == 1 and level.checkpoint_id == "trecho_2", "A gap death must retry the second section")
    await defeat_wave(level, 1)
    level._process(0.0)
    level.player.position = Vector2(level.pits[0].position.x - 35.0, 450)
    level.player.facing = 1
    level.player._start_dodge(1.0)
    level.player.set_physics_process(true)
    for _frame in range(30):
        await physics_frame
        if level.player.is_falling:
            break
    level.player.set_physics_process(false)
    check(level.player.is_falling and level.player.hp == 0, "A grounded roll must fall rather than bypass the gap")
    level = await restart(level)
    await defeat_wave(level, 1)
    level._process(0.0)
    level.player.position = Vector2(level.pits[0].position.x - 48.0, 450)
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
    check(peak_height > 50 and level.player.has_jumped, "The normal jump input must show a visible airborne arc")
    check(level.player.position.x > level.pits[0].end.x + level.PIT_DEATH_MARGIN and level.player.hp > 0 and not level.player.is_falling, "One ordinary running jump must clear the actual gap")
    check(is_zero_approx(level.player.jump_height), "The crossing must end with a safe landing")
    level.player.position = Vector2(level.THIRD_STAGE_GATE - 1.0, 450)
    level._process(0.0)
    check(level.wave_index == 1, "The third fight must wait until its gate")
    level.player.position.x += 1
    level._process(0.0)
    freeze(level)
    check(level.wave_index == 2 and level.checkpoint_id == "trecho_3", "Entering section three must save a checkpoint beyond the hole")
    check_active_wave(level, 2)
    level = await restart(level)
    check(level.wave_index == 2 and level.checkpoint_id == "trecho_3" and level.player.hp == level.player.max_hp, "Retry must restore a playable third encounter")
    check(alive_count(level.waves[0]) + alive_count(level.waves[1]) == 0, "Both completed encounters must stay cleared after a third-section retry")
    check(level.player.position.x > level.pits[0].end.x + 28.0, "The third checkpoint must stay safely beyond the gap")
    await check_hazards(level)
    level = current_scene
    freeze(level)
    level._update_hud()
    check(level.health_bar.value == level.player.hp and level.health_bar.max_value == level.player.max_hp, "The shared health HUD must remain accurate")
    level.player.position = Vector2(4200, 450)
    level._process(0.0)
    check(not level.finished and not level.boss_intro_running, "The last enemies must block the laboratory entrance")
    level.player.position = Vector2(level.THIRD_STAGE_GATE + 250.0, 450)
    await defeat_wave(level, 2)
    level._process(0.0)
    check(not level.finished and level.road_open, "Clearing combat must still require walking to the laboratory entrance")
    check(Progress.completed_stages() == 5 and not Progress.is_available(6), "Exploration must not complete the ritual story or unlock Corpo-Seco")
    level.player.position = Vector2(4200, 450)
    level._process(0.0)
    check(current_scene.scene_file_path == STAGE_PATH and is_instance_valid(level.cuca_fight), "Walking into the laboratory must keep the same scene and install the Cuca battle")
    check(level.checkpoint_id == "boss" and Progress.checkpoint().get("id", "") == "boss", "The laboratory entrance must save its own retry checkpoint")
    check(Progress.completed_stages() == 5 and not Progress.is_available(6), "Starting Cuca must leave the final ritual and Corpo-Seco progression pending")
    if failures == 0:
        print("PASS: phase-six availability, three gated encounters, gap deaths/jump crossing, checkpoint retries, torch-free dark parallax, ceiling traps targeting the crossed lane, pause, avoidable 50% damage and laboratory boss entrance")
    quit(0 if failures == 0 else 1)

func check_scenery(level: Node) -> void:
    var scenery: Node2D = level.cave_scenery
    check(is_instance_valid(scenery), "The cave must install its dedicated scenery")
    check(level.find_children("CaveTorch*", "", true, false).is_empty(), "The cave must no longer display wall torches or their lights")
    check(level.find_children("*", "PointLight2D", true, false).is_empty(), "Removed torch illumination must not remain in the map")
    var ambient: Color = scenery.ambient.color
    check(ambient.r > 0.70 and ambient.r < 0.95 and ambient.g < 0.95, "Dark ambient light must retain enough visibility without torches")
    for stone: Node2D in level.stalactites:
        check(stone.position.y < 180 and stone.position.y + stone.HANGING_HEIGHT < 260, "Hanging stalactites must attach above the view and stay at the ceiling")
    var ground: Sprite2D = level.get_node("Ground")
    var background: Sprite2D = level.get_node("Background")
    check("Fases6" in ground.texture.resource_path and "Fases6" in background.texture.resource_path, "The cave must use the supplied phase-six ground and background")
    var camera: Camera2D = level.player.get_node("Camera2D")
    camera.force_update_scroll()
    await process_frame
    var old_ground := ground.position
    var old_background := background.position
    var original_center := camera.get_screen_center_position()
    var pan := Camera2D.new()
    level.add_child(pan)
    pan.position = original_center
    pan.zoom = camera.zoom
    pan.make_current()
    pan.force_update_scroll()
    await process_frame
    var before_pan := background.position
    pan.position.x += 180
    pan.force_update_scroll()
    await process_frame
    var drift := absf(background.position.x - before_pan.x)
    check(drift > 1.0 and drift < 180.0 and ground.position == old_ground, "Camera traversal must separate the background from the fixed physical ground")
    camera.make_current()
    camera.reset_smoothing()
    camera.force_update_scroll()
    pan.queue_free()
    await process_frame
    check(background.position.distance_to(old_background) < 1.0, "Returning to gameplay must restore the original parallax framing")
    var menu = level.get_node("PauseMenu")
    menu._set_paused(true)
    var clock = scenery.get("elapsed")
    await create_timer(0.15, true).timeout
    check(paused and menu.panel.visible and scenery.get("elapsed") == clock, "Pause must freeze the cave atmosphere clock")
    menu._start_or_resume()
    check(not paused and not menu.panel.visible, "Resume must restore normal cave play")

func check_hazards(level: Node) -> void:
    var falling_count := 0
    var decorative_count := 0
    for stone: Node2D in level.stalactites:
        if stone.falls:
            falling_count += 1
        else:
            decorative_count += 1
    check(falling_count >= 3 and decorative_count >= 2, "The ceiling must mix real falling hazards and harmless decorative stalactites")
    var hero = level.player
    # A rock must trigger wherever the player passes under it, including
    # both edges of the lane, then leave its impact marker fixed in place.
    for depth in [345.0, 555.0]:
        hero.position = Vector2(3500, depth)
        var crossed := new_stone(level, Vector2(3500, 450), true, 2)
        crossed.set_physics_process(false)
        hero.position.x += crossed.TRIGGER_HALF_WIDTH + 1.0
        crossed._physics_process(0.0)
        check(crossed.state == crossed.State.HANGING, "A trap must wait until the player is directly below it")
        hero.position.x -= 2.0
        crossed._physics_process(0.0)
        check(crossed.state == crossed.State.WARNING and is_equal_approx(crossed.landing_y, depth), "Crossing under a trap must capture the player's current ground lane")
        hero.position.y = 450
        crossed._physics_process(0.10)
        check(is_equal_approx(crossed.landing_y, depth), "A warning must keep its impact point fixed when the player moves")
        crossed.free()
    hero.position = Vector2(3500, 555)
    hero.hp = hero.max_hp
    hero.damage_cooldown = 0
    var hit := new_stone(level, Vector2(hero.position.x, 450), true, 2)
    await physics_frame
    await physics_frame
    check(hit.state == hit.State.WARNING and hit.triggered and hero.hp == hero.max_hp and is_equal_approx(hit.landing_y, 555.0), "An active stalactite must warn and target the player's actual lane before dealing damage")
    paused = true
    var warning_time: float = hit.state_timer
    var warning_position: Vector2 = hit.visual.position
    await create_timer(0.15, true).timeout
    check(hit.state_timer == warning_time and hit.visual.position == warning_position and hit.state == hit.State.WARNING, "Pause must freeze the hazard warning and shaking sprite")
    paused = false
    hit._begin_fall()
    paused = true
    var tip_before_pause: float = hit.tip_y
    var speed_before_pause: float = hit.fall_speed
    await create_timer(0.15, true).timeout
    check(hit.tip_y == tip_before_pause and hit.fall_speed == speed_before_pause, "Pause must also freeze the descending rock")
    paused = false
    await wait_for_shatter(hit)
    var half_damage := ceili(hero.max_hp * 0.5)
    check(hit.damage_dealt and hit.hit_attempted and hero.hp == hero.max_hp - half_damage, "A direct falling hit must remove exactly 50% of maximum health")
    check(hit.state == hit.State.SHATTERED and hit.visual.animation == "shatter", "A landed stalactite must use its shatter sequence")
    hero.damage_cooldown = 0
    hit._physics_process(7.0)
    check(hero.hp == hero.max_hp - half_damage and hit.state == hit.State.SHATTERED, "A spent stalactite must never hit or trigger a second time")
    hit.free()

    hero.hp = hero.max_hp
    hero.damage_cooldown = 0
    var miss := new_stone(level, hero.position, true, 2)
    miss._physics_process(0.0)
    check(miss.state == miss.State.WARNING, "The next falling rock must telegraph independently")
    hero.position.x += 180
    await wait_for_shatter(miss)
    check(not miss.damage_dealt and hero.hp == hero.max_hp, "Moving sideways during the warning must avoid the falling rock")
    miss.free()

    hero.position = Vector2(3500, 450)
    var depth_miss := new_stone(level, hero.position, true, 2)
    depth_miss._physics_process(0)
    hero.position.y += 60
    await wait_for_shatter(depth_miss)
    check(not depth_miss.damage_dealt and hero.hp == hero.max_hp, "A different ground lane must remain safe from a nearby falling sprite")
    depth_miss.free()

    hero.position = Vector2(3500, 450)
    var decoration := new_stone(level, hero.position, false, 2)
    decoration._physics_process(2.0)
    check(decoration.state == decoration.State.HANGING and not decoration.triggered and hero.hp == hero.max_hp, "Decorative ceiling stones must remain hanging when approached")
    decoration.free()
    var inactive := new_stone(level, hero.position, true, 1)
    inactive._physics_process(2.0)
    check(inactive.state == inactive.State.HANGING and not inactive.triggered, "An inactive encounter must not trigger its hazards remotely")
    inactive.free()

    # One large physical frame must sweep the whole fall, rather than tunnel.
    hero.hp = hero.max_hp
    hero.damage_cooldown = 0
    var swept := new_stone(level, hero.position, true, 2)
    swept.set_physics_process(false)
    swept._begin_fall()
    swept._physics_process(1.0)
    check(swept.damage_dealt and hero.hp == hero.max_hp - half_damage, "A low-frame-rate fall must still hit exactly once")
    swept.free()

    hero.hp = 4
    hero.damage_cooldown = 0
    var fatal := new_stone(level, hero.position, true, 2)
    fatal.set_physics_process(false)
    fatal._begin_fall()
    fatal._physics_process(1.0)
    check(hero.hp == 0 and level.death_screen.visible, "A half-health hazard must cause a normal defeat when current HP is insufficient")
    level = await restart(level)
    check(level.wave_index == 2 and level.player.hp == level.player.max_hp, "Hazard death must restore the current checkpoint and all health")
    for restored: Node2D in level.stalactites:
        check(restored.state == restored.State.HANGING and not restored.triggered, "Retry must restore all ceiling hazards to their initial state")

func new_stone(level: Node2D, landing: Vector2, falls: bool, section: int) -> Node2D:
    var stone := preload("res://scripts/CaveStalactite.gd").new()
    stone.configure(level, Vector2(landing.x, 150), landing.y, falls, section)
    level.add_child(stone)
    return stone

func wait_for_shatter(stone: Node2D) -> void:
    for _frame in range(180):
        await physics_frame
        if stone.state == stone.State.SHATTERED:
            return
    check(false, "A triggered stalactite must land and shatter within three seconds")

func open_scene() -> void:
    paused = false
    change_scene_to_file(STAGE_PATH)
    await process_frame
    await process_frame

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

func check_active_wave(level: Node, expected: int) -> void:
    freeze(level)
    for index in level.waves.size():
        for enemy in level.waves[index]:
            if is_instance_valid(enemy) and enemy.hp > 0:
                check(enemy.visible == (index == expected), "Only the active section's living enemies may be visible")

func alive_count(wave: Array) -> int:
    var count := 0
    for enemy in wave:
        if is_instance_valid(enemy) and enemy.hp > 0:
            count += 1
    return count

func defeat_wave(level: Node, index: int) -> void:
    for enemy in level.waves[index]:
        if is_instance_valid(enemy) and enemy.hp > 0:
            enemy.take_damage(enemy.hp)
    await process_frame

func restart(level: Node) -> Node:
    if level.player.hp > 0:
        level.player.damage_cooldown = 0
        level.player.take_damage(100)
    level._reset_scene()
    while root.get_node("SceneTransition").busy:
        await process_frame
    await process_frame
    check(current_scene.scene_file_path == STAGE_PATH and not paused, "Checkpoint retry must stay in phase six and resume the game")
    freeze(current_scene)
    return current_scene

func set_space(pressed: bool) -> void:
    var event := InputEventKey.new()
    event.keycode = KEY_SPACE
    event.physical_keycode = KEY_SPACE
    event.pressed = pressed
    Input.parse_input_event(event)
    Input.flush_buffered_events()
