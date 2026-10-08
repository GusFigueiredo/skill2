extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    var view := SubViewport.new()
    view.size = Vector2i(1280, 720)
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    for stage_number in [3, 4]:
        var level = load("res://rio_negro%d.tscn" % stage_number).instantiate()
        view.add_child(level)
        level.set_process(false)
        level.set_physics_process(false)
        for enemy in level.waves[0]:
            if enemy.spawn_tween != null:
                enemy.spawn_tween.custom_step(2.0)
        for actor in get_nodes_in_group("player") + get_nodes_in_group("enemy"):
            actor.set_physics_process(false)
        level.player.position.x = 500.0 if stage_number == 3 else 260.0
        var camera = level.player.get_node("Camera2D")
        camera.reset_smoothing()
        camera.force_update_scroll()
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        var screenshot := view.get_texture().get_image()
        screenshot.save_png("res://rio-negro%d-preview.png" % stage_number)
        level.free()
    view.free()
    print("PASS: captured both Rio Negro stage previews")
    quit()
