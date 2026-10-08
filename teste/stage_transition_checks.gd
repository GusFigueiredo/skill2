extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func run_checks() -> void:
    change_scene_to_file("res://main.tscn")
    await process_frame
    await process_frame
    var level = current_scene
    level.set_process(false)
    level.player.position = Vector2(1600, 430)
    for actor in get_nodes_in_group("player") + get_nodes_in_group("enemy"):
        actor.set_physics_process(false)
    await process_frame
    var transition = root.get_node("SceneTransition")
    level.tutorial.step = level.tutorial.Step.COMPLETE
    for enemy in level.waves[0]:
        enemy.take_damage(enemy.hp)
    level._process(0.016)
    assert(transition.busy and not paused and transition.phase == "waiting_for_defeat")
    assert(level.player.sprite.animation == "idle")
    assert(get_nodes_in_group("enemy_defeat_visuals").size() == 2)
    await create_timer(0.2, true).timeout
    assert(transition.phase == "waiting_for_defeat")
    assert(level.player.sprite.animation == "idle")
    while transition.phase == "waiting_for_defeat":
        await process_frame
    assert(get_nodes_in_group("enemy_defeat_visuals").is_empty())
    assert(paused and transition.phase == "walking_out")
    assert(not transition.screen.visible and not transition.fade_screen.visible)
    assert(level.player.sprite.animation == "walk" and not level.player.sprite.flip_h)
    var camera_point: Vector2 = transition.exit_camera.global_position
    var start_x: float = level.player.global_position.x
    await create_timer(0.5, true).timeout
    assert(level.player.global_position.x > start_x)
    assert(transition.exit_camera.global_position == camera_point)
    assert(transition.phase == "walking_out")
    while transition.phase == "walking_out":
        await process_frame
    assert(transition.phase == "fading_out")
    assert(level.player.global_position.x >= transition.exit_target_x - 0.1)
    assert(not transition.screen.visible, "Loading must start only after exit and fade")
    await create_timer(0.25, true).timeout
    assert(transition.fade_screen.modulate.a > 0 and transition.fade_screen.modulate.a < 1)
    while transition.phase == "fading_out":
        await process_frame
    assert(transition.phase == "loading" and transition.screen.visible)
    assert(is_equal_approx(transition.fade_screen.modulate.a, 1.0))
    while transition.phase == "loading":
        await process_frame
    assert(transition.phase == "fading_in")
    assert(current_scene.scene_file_path == "res://ratanaba2.tscn")
    assert(paused and not transition.screen.visible and transition.fade_screen.visible)
    while transition.busy:
        await process_frame
    assert(not paused and not transition.fade_screen.visible)
    assert(preload("res://scripts/CampaignProgress.gd").completed_stages() == 1)
    level = current_scene
    level.set_process(false)
    for actor in get_nodes_in_group("player") + get_nodes_in_group("enemy"):
        actor.set_physics_process(false)
    level.player.position = Vector2(3300, 430)
    level.wave_index = 2
    level.boss.take_damage(level.boss.hp)
    await process_frame
    level._process(0.016)
    assert(transition.phase == "waiting_for_defeat")
    assert(level.player.sprite.animation == "idle")
    assert(not level.death_screen.visible, "Victory uses stage exit, not death presentation")
    while transition.busy:
        await process_frame
    assert(current_scene.scene_file_path == "res://level_map.tscn")
    assert(preload("res://scripts/CampaignProgress.gd").completed_stages() == 2)
    assert(not paused)
    print("PASS: walking right offscreen, stationary camera, fade-out before loading, next-stage fade-in and shared boss-stage exit")
    quit()
