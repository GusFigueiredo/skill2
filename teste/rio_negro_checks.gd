extends SceneTree

const Progress = preload("res://scripts/CampaignProgress.gd")

func _initialize() -> void:
    call_deferred("run_checks")

func run_checks() -> void:
    create_timer(55.0, true).timeout.connect(func():
        push_error("Rio Negro checks timed out")
        quit(1)
    )
    assert(Progress.completed_stages() == 0, "Run with isolated fresh APPDATA")
    Progress.complete_stage(2)
    assert(Progress.completed_stages() == 0, "Cannot skip the first two stages")
    Progress.complete_stage(0)
    Progress.complete_stage(1)
    assert(Progress.is_available(2) and not Progress.is_available(3))
    var previous_stage = load("res://ratanaba2.tscn").instantiate()
    assert(previous_stage.next_stage_path == Progress.stage_path(2))
    previous_stage.free()

    change_scene_to_file("res://level_map.tscn")
    await process_frame
    await process_frame
    var map = current_scene
    assert(not map.stage_buttons[2].disabled and map.stage_buttons[3].disabled)
    map._show_stage(2)
    assert(not map.start_button.disabled and "dispon" in map.details_label.text)
    map._start_selected_stage()
    await wait_for_transition()
    assert(current_scene.scene_file_path == Progress.stage_path(2))
    await check_stage(2, 3)

    # A defeat must restart phase 3 itself, without replaying the tutorial.
    current_scene.player.take_damage(100)
    assert(current_scene.death_screen.visible)
    current_scene._reset_scene()
    await wait_for_transition()
    assert(current_scene.scene_file_path == Progress.stage_path(2))
    await check_stage(2, 3)
    await defeat_wave()
    assert(current_scene.scene_file_path == Progress.stage_path(3))
    assert(Progress.completed_stages() == 3)
    await check_stage(3, 4)

    current_scene._reset_scene()
    await wait_for_transition()
    assert(current_scene.scene_file_path == Progress.stage_path(3))
    await check_stage(3, 4)
    await defeat_wave()
    assert(current_scene.scene_file_path == "res://level_map.tscn")
    assert(Progress.completed_stages() == 4)
    for index in range(4):
        assert(not current_scene.stage_buttons[index].disabled)
    for index in range(4, 7):
        assert(current_scene.stage_buttons[index].disabled)
    current_scene._show_stage(3)
    current_scene._start_selected_stage()
    await wait_for_transition()
    assert(current_scene.scene_file_path == Progress.stage_path(3), "Map must launch phase 4")
    await check_stage(3, 4)
    print("PASS: Rio Negro scenery, encounters, damage, restarts, 3->4->map, sequential save and map launch")
    quit()

func check_stage(index: int, enemy_count: int) -> void:
    var level = current_scene
    level.set_process(false)
    level.set_physics_process(false)
    assert(level.stage_index == index and not level.tutorial_stage)
    assert(level.tutorial.step == level.tutorial.Step.COMPLETE and not level.tutorial.visible)
    assert(level.pits.is_empty())
    if index == 3:
        assert(level.waves == [[level.boss]])
        assert(level.boss.visible and level.boss.hp == 6)
        assert(level.get_node("HUD/BossHealth").visible)
        assert(level.get_node("Ground").texture.resource_path.ends_with("chao boss fight Iara.png"))
        level.player.set_physics_process(false)
        level.boss.set_physics_process(false)
        await process_frame
        return
    assert(level.waves.size() == 1 and level.waves[0].size() == enemy_count)
    assert(not level.boss.visible and not level.boss.is_physics_processing())
    assert(not level.get_node("HUD/BossHealth").visible)
    assert(level.get_node("Background").texture.resource_path == "res://sprites/cenario/Fases3e4/background.png")
    assert(level.get_node("Ground").texture.resource_path == "res://sprites/cenario/Fases3e4/chao.png")
    for scenery in [level.get_node("Background"), level.get_node("Ground")]:
        assert(scenery.position.x + scenery.region_rect.size.x * scenery.scale.x > 4800)
    for enemy in level.waves[0]:
        enemy.spawn_tween.custom_step(2.0)
        assert(enemy.visible and enemy.is_physics_processing())
        assert(level.arena_bounds.has_point(enemy.position))
        enemy.set_physics_process(false)
    level.player.set_physics_process(false)
    level.check_player_floor(level.player.position)
    assert(not level.player.is_falling)
    var enemy = level.waves[0][0]
    var hp: int = enemy.hp
    enemy.take_damage(1)
    assert(enemy.hp == hp - 1)
    await process_frame

func defeat_wave() -> void:
    var level = current_scene
    var transition = root.get_node("SceneTransition")
    level._process(0.016)
    assert(not level.finished, "A surviving enemy must prevent victory")
    if level.stage_index == 3:
        # The full charm/minion cycle is covered by iara_checks.gd.
        level.state = level.State.VULNERABLE
    for enemy in level.waves[0]:
        enemy.take_damage(enemy.hp)
    level._process(0.016)
    assert(level.finished and transition.busy)
    while transition.phase == "waiting_for_defeat":
        await process_frame
    assert(transition.phase == "celebrating")
    await create_timer(1.1, true).timeout
    assert(transition.phase == "celebrating", "Victory feedback must last longer than a second")
    await wait_for_transition()

func wait_for_transition() -> void:
    while root.get_node("SceneTransition").busy:
        await process_frame
    assert(not paused)
