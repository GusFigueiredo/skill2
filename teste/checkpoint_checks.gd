extends SceneTree

const Progress = preload("res://scripts/CampaignProgress.gd")
const RIVER_FRAMES = preload("res://sprites/characters/enemy_map2.tres")
var failures := 0

func _initialize() -> void:
    call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error(message)

func run_checks() -> void:
    create_timer(65.0, true).timeout.connect(func():
        push_error("Checkpoint checks timed out")
        quit(1)
    )
    if "--verify-persistence" in OS.get_cmdline_user_args():
        check(Progress.checkpoint().get("stage", -1) == 3, "Checkpoint must survive a new game process")
        await open_scene("res://menu.tscn")
        var menu = current_scene
        check(not menu.buttons.has_node("ContinueCheckpointButton"), "Menu must not offer checkpoint continuation even with a saved checkpoint")
        check(menu.primary_button.text == "Jogar", "Menu must keep its normal start action")
        var menu_actions: Array[String] = []
        for child in menu.buttons.get_children():
            if child is Button:
                menu_actions.append(child.text)
        check(menu_actions == ["Jogar", "Controles", "Sair"], "Main menu must expose only its three normal actions")
        check(Progress.checkpoint().get("stage", -1) == 3, "Opening the menu must preserve the saved checkpoint")
        menu._start_or_resume()
        await wait_for_transition()
        check(current_scene.scene_file_path == "res://prologue.tscn", "Jogar must open the prologue with a saved checkpoint")
        for _frame in current_scene.STORY_FRAMES.size():
            current_scene._advance()
        await wait_for_transition()
        check(current_scene.scene_file_path == "res://level_map.tscn" and current_scene.selected_stage == 0, "Prologue must lead to the normal stage map")
        current_scene._start_selected_stage()
        await wait_for_transition()
        check(current_scene.stage_index == 0 and current_scene.checkpoint_id == "start", "Map selection must start a fresh phase rather than resume the saved Iara fight")
        check(current_scene.player.hp == current_scene.player.max_hp, "A fresh phase must start with full health")
        print("PASS: checkpoint persists across game processes, menu omits continuation and Jogar starts the normal route")
        quit(failures)
        return

    check(Progress.completed_stages() == 0 and Progress.checkpoint().is_empty(), "Run with isolated fresh APPDATA")
    await open_scene("res://main.tscn")
    var level = current_scene
    freeze_level(level)
    check(level.get_node("Enemy1/Sprite").frames_override == null, "Tutorial must retain the original enemy")
    check(Progress.checkpoint()["id"] == "start", "Every phase must save its starting checkpoint")
    level.tutorial.step = level.tutorial.Step.ATTACK
    level.player.position = Vector2(1300, 430)
    level.tutorial._start_enemy_arrival()
    check(Progress.checkpoint()["id"] == "tutorial_combat", "Tutorial combat must save a checkpoint after the hole")
    level.player.take_damage(100)
    level._reset_scene()
    await wait_for_transition()
    level = current_scene
    freeze_level(level)
    check(level.checkpoint_id == "tutorial_combat" and level.tutorial.step == level.tutorial.Step.ATTACK, "Retry must skip completed movement lessons")
    check(level.player.position.x == 1300 and level.player.hp == level.player.max_hp, "Retry must restore safe position and full health")
    check(level.tutorial.lesson_enemy == level.waves[0][0], "Retry must restore the guided combat enemy")
    Progress.complete_stage(0)
    check(Progress.completed_stages() == 1 and Progress.checkpoint().is_empty(), "Victory must clear the finished checkpoint")

    await open_scene("res://ratanaba2.tscn")
    level = current_scene
    freeze_level(level)
    check(level.get_node("Enemy1/Sprite").frames_override == null, "Ratanaba must retain the original enemy")
    for enemy in level.waves[0]:
        enemy.take_damage(enemy.hp)
    await process_frame
    level.player.position = Vector2(1500, 430)
    level._process(0.016)
    check(level.wave_index == 1 and Progress.checkpoint()["id"] == "wave_2", "Second encounter must save a checkpoint")
    level.player.take_damage(100)
    check(level.reset_button.text == "Voltar ao checkpoint", "Death action must describe checkpoint retry")
    level._reset_scene()
    await wait_for_transition()
    level = current_scene
    freeze_level(level)
    check(level.wave_index == 1 and level.player.position.x == 1500, "Retry must return to second encounter")
    check(level.player.hp == level.player.max_hp, "Retry must refill player health")
    check(not level.has_node("Enemy1") and not level.has_node("Enemy2"), "Completed first wave must stay removed")
    for enemy in level.waves[1]:
        check(enemy.hp == enemy.max_hp, "Current wave must restart with full enemy health")
        enemy.take_damage(enemy.hp)
    await process_frame
    level.player.position = Vector2(2600, 440)
    level._process(0.016)
    check(level.boss_intro_running and Progress.checkpoint()["id"] == "boss", "Boitata must save before the boss entrance")
    level._reset_scene()
    await wait_for_transition()
    level = current_scene
    freeze_level(level)
    check(level.wave_index == 2 and level.boss_area_entered, "Boss retry must skip both earlier waves")
    check(level.boss_intro_running and level.boss.hp == level.boss.max_hp, "Boss retry must reset the boss and entrance")
    check(level.player.hp == level.player.max_hp and level.player.position.x >= 2600, "Boss retry must respawn safely beyond the hole")
    check(not level.has_node("Enemy3") and not level.has_node("Enemy4") and not level.has_node("Enemy5"), "Boss retry must remove earlier enemies")
    Progress.complete_stage(1)
    check(Progress.completed_stages() == 2, "Checkpoint writes must preserve campaign unlocks")

    await open_scene("res://rio_negro3.tscn")
    level = current_scene
    freeze_level(level)
    for enemy in level.waves[0]:
        check(enemy.get_node("Sprite").sprite_frames == RIVER_FRAMES, "All phase 3 enemies must use the new sheet")
        check(enemy.combat_bounds.size.y > 50 and enemy.combat_bounds.size.x > 30, "New sheet must have usable combat geometry")
    var initial_position: Vector2 = level.player.position
    level.player.position.x = 1100
    level.waves[0][0].take_damage(1)
    level.player.take_damage(100)
    level._reset_scene()
    await wait_for_transition()
    level = current_scene
    freeze_level(level)
    check(level.player.position == initial_position and level.waves[0][0].hp == level.waves[0][0].max_hp, "Phase 3 retry must reset its current encounter")
    Progress.complete_stage(2)

    await open_scene("res://rio_negro4.tscn")
    level = current_scene
    freeze_level(level)
    level._spawn_trance_enemy()
    check(level.trance_enemy.get_node("Sprite").sprite_frames == RIVER_FRAMES, "Trance pursuer must use the new sheet")
    level._spawn_minions()
    for minion in level.minions:
        check(minion.get_node("Sprite").sprite_frames == RIVER_FRAMES, "Iara's minions must use the new sheet")
    level.boss.hp = 2
    level.player.take_damage(100)
    level._reset_scene()
    await wait_for_transition()
    level = current_scene
    freeze_level(level)
    check(level.player.position == Vector2(level.BOSS_GATE, 460) and level.player.hp == level.player.max_hp, "Iara retry must return to the dry shore with full health")
    check(level.state == level.State.IDLE and level.boss.hp == 6 and level.minions.is_empty() and level.trance_enemy == null, "Iara retry must reset all bossfight states")

    # Explicitly selecting a stage starts a fresh attempt, rather than applying a stale checkpoint.
    Progress.save_checkpoint(1, "boss", Vector2(2600, 440))
    await open_scene("res://level_map.tscn")
    current_scene._show_stage(1)
    current_scene._start_selected_stage()
    await wait_for_transition()
    check(current_scene.wave_index == 0 and current_scene.checkpoint_id == "start", "Map selection must start the selected phase from its beginning")
    check(Progress.completed_stages() == 3, "Replay checkpoints must preserve unlocked phases")
    Progress.complete_stage(3)
    Progress.save_checkpoint(3, "start", Vector2(440, 460))
    print("PASS: tutorial, wave and boss checkpoints, full-health retries, campaign preservation, map replay and river enemy scope")
    quit(failures)

func open_scene(path: String) -> void:
    paused = false
    change_scene_to_file(path)
    await process_frame
    await process_frame

func freeze_level(level: Node) -> void:
    if level.stage_index == 3:
        preload("res://iara_test_support.gd").reach_boss(level)
    if level.stage_index == 3 and level.boss_intro_running:
        level.entrance.sequence.custom_step(30.0)
    level.set_process(false)
    level.set_physics_process(false)
    for actor in get_nodes_in_group("player") + get_nodes_in_group("enemy"):
        actor.set_physics_process(false)

func wait_for_transition() -> void:
    while root.get_node("SceneTransition").busy:
        await process_frame
    await process_frame
    check(not paused, "Checkpoint loading must resume the scene tree")
