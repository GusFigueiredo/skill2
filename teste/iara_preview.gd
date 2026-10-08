extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    var view := SubViewport.new()
    view.size = Vector2i(1280, 720)
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var fight = load("res://rio_negro4.tscn").instantiate()
    view.add_child(fight)
    fight.set_physics_process(false)
    fight.player.set_physics_process(false)
    await capture_frame(view, "idle")
    fight._physics_process(fight.INTRO_IDLE_SECONDS + 0.01)
    fight._physics_process(1.25)
    fight.boss.get_node("Sprite")._process(0)
    fight.boss.get_node("Sprite").set_frame_and_progress(3, 0)
    await capture_frame(view, "preparing")
    fight._physics_process(fight.state_timer + 0.01)
    fight._physics_process(fight.CAST_SECONDS * 0.4)
    await capture_frame(view, "casting")
    fight._physics_process(fight.state_timer + 0.01)
    fight.trance_enemy.spawn_tween.custom_step(2)
    fight.trance_enemy.set_physics_process(false)
    fight.player.position = Vector2(440, 460)
    fight.camera_tween.custom_step(0.4)
    fight._process(0.5)
    await capture_frame(view, "seduction")
    Input.action_press("ui_left")
    fight.player._physics_process(0.01)
    await capture_frame(view, "key-pressed")
    Input.action_release("ui_left")
    for index in fight.RESISTANCE_REQUIRED:
        fight.register_resistance(-1 if index % 2 == 0 else 1)
        if fight.state == fight.State.SEDUCING:
            fight._physics_process(fight.RESISTANCE_COOLDOWN)
    fight._physics_process(0.76)
    fight.camera_tween.custom_step(0.3)
    for minion in fight.minions:
        if minion.spawn_tween.is_valid():
            minion.spawn_tween.custom_step(2)
        minion.set_physics_process(false)
    await capture_frame(view, "fallen")
    fight.state = fight.State.VULNERABLE
    fight.state_timer = 2
    fight.player.position = Vector2(470, 450)
    for minion in fight.minions:
        minion.hide()
    await capture_frame(view, "vulnerable")
    fight._begin_drowning()
    fight._physics_process(2)
    await capture_frame(view, "drowning")
    fight.free()
    view.free()
    print("PASS: Iara phase previews captured")
    quit()

func capture_frame(view: SubViewport, phase: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    view.get_texture().get_image().save_png("res://iara-%s-preview.png" % phase)
