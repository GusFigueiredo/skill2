extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func run_checks() -> void:
    change_scene_to_file("res://ratanaba2.tscn")
    await process_frame
    await process_frame
    var fight = current_scene
    fight.set_process(false)
    for enemy in get_nodes_in_group("enemy"):
        enemy.set_physics_process(false)
    fight.player.set_physics_process(false)
    fight.boss.show()
    fight.boss.position = Vector2(3150, 450)
    fight.player.position = Vector2(3050, 450)
    var gameplay_camera := fight.player.get_node("Camera2D") as Camera2D
    gameplay_camera.reset_smoothing()
    gameplay_camera.force_update_scroll()
    var gameplay_center := gameplay_camera.get_screen_center_position()
    fight.boss.take_damage(100)
    var conversation = fight.get_node("BoitataDialogue")
    conversation.opening_tween.pause()
    assert(conversation.camera.get_screen_center_position().is_equal_approx(gameplay_center), "Dialogue must preserve the gameplay framing")
    assert(conversation.camera.limit_top == gameplay_camera.limit_top and conversation.camera.limit_bottom == gameplay_camera.limit_bottom, "Dialogue must stay inside the gameplay's vertical limits")
    await process_frame
    assert(conversation.camera.get_screen_center_position().is_equal_approx(gameplay_center), "Dialogue camera must remain stationary")
    assert(is_instance_valid(fight.boss) and fight.boss.visible and fight.boss.hp == 0)
    assert(fight.boss.get_node("Sprite").animation == "idle")
    assert(fight.boss_intro_running and not fight.finished)
    assert(not conversation.dialogue.visible, "Dialogue must remain hidden while Boitata catches her breath")
    assert(is_equal_approx(conversation.DIALOGUE_DELAY_SECONDS, 2.0))
    assert(conversation.boss_visual.speed_scale < 1.0, "Defeated Boitata must idle more slowly")
    assert(conversation.boss_visual.modulate.r < fight.boss.body_color.r, "Defeated Boitata must look weakened")
    var resting_position: Vector2 = conversation.boss_visual.position
    var resting_scale: Vector2 = conversation.boss_visual.scale
    conversation._process(0.4)
    assert(not conversation.boss_visual.position.is_equal_approx(resting_position) or not conversation.boss_visual.scale.is_equal_approx(resting_scale), "Resting pose must breathe gently")
    assert(conversation.boss_visual.position.distance_to(resting_position) < 10.0, "Breathing must not displace the boss")
    conversation.opening_tween.custom_step(1.9)
    assert(not conversation.dialogue.visible, "Dialogue must not open before the two-second pause")
    conversation.opening_tween.custom_step(0.2)
    assert(conversation.dialogue.visible, "Dialogue must open after the two-second pause")
    assert(conversation.dialogue.speaker == "boitata")
    assert(not root.get_node("SceneTransition").busy, "Victory must wait for all dialogue")
    for index in range(7):
        assert(conversation.line_index == index)
        assert(conversation.dialogue.speaker == conversation.LINES[index][0])
        conversation.dialogue.advance()
        assert(conversation.line_index == index, "Revealing text must not skip the line")
        var advances := 0
        while is_instance_valid(conversation) and conversation.line_index == index and advances < 30:
            conversation.dialogue.advance()
            advances += 1
            await create_timer(0.03).timeout
        assert(advances < 30, "All pages of a turn must finish before opening the next speaker")
    while is_instance_valid(conversation) and not fight.finished:
        await process_frame
    assert(fight.finished and root.get_node("SceneTransition").busy)
    assert(is_instance_valid(fight.boss) and fight.boss.visible)
    print("PASS: Boitata rests with a tired idle, dialogue waits two seconds, fixed gameplay camera, seven paginated turns with matching portraits, completion and exit delayed until the last line")
    quit()
