extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    create_timer(45.0, true).timeout.connect(func(): quit(1))
    var output := OS.get_environment("TEMP").path_join("skill2-checkpoint-previews")
    DirAccess.make_dir_recursive_absolute(output)
    var view := SubViewport.new()
    view.size = Vector2i(1280, 720)
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var progress = preload("res://scripts/CampaignProgress.gd")
    progress.save_checkpoint(0, "start", Vector2(220, 430))
    var menu = load("res://menu.tscn").instantiate()
    view.add_child(menu)
    await create_timer(2.0).timeout
    await RenderingServer.frame_post_draw
    view.get_texture().get_image().save_png(output.path_join("menu.png"))
    menu.free()
    for stage in [3, 4]:
        var level = load("res://rio_negro%d.tscn" % stage).instantiate()
        view.add_child(level)
        if stage == 4:
            preload("res://iara_test_support.gd").reach_boss(level)
            level.entrance.finish()
        level.set_process(false)
        level.set_physics_process(false)
        if stage == 4:
            level._spawn_minions()
        for actor in get_nodes_in_group("player") + get_nodes_in_group("enemy"):
            if actor.get("spawn_tween") != null:
                actor.spawn_tween.custom_step(3.0)
            actor.set_physics_process(false)
            actor.get_node("Sprite").set_process(false)
            actor.get_node("Sprite").play("idle")
        if stage == 3:
            level.player.position.x = 500
        var camera = level.player.get_node("Camera2D")
        camera.reset_smoothing()
        camera.force_update_scroll()
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        view.get_texture().get_image().save_png(output.path_join("phase%d.png" % stage))
        if stage == 3:
            level.trigger_death()
            level.death_screen.reveal.custom_step(5.0)
            await process_frame
            await RenderingServer.frame_post_draw
            view.get_texture().get_image().save_png(output.path_join("death.png"))
        level.free()
    view.free()
    var frames = preload("res://sprites/characters/enemy_map2.tres")
    var names := ["idle", "walk", "walk_up", "walk_down", "attack", "hurt", "death"]
    var atlas := Image.create(2048, names.size() * 128, false, Image.FORMAT_RGBA8)
    atlas.fill(Color("203a45"))
    for row in names.size():
        for index in frames.get_frame_count(names[row]):
            var frame_image: Image = frames.get_frame_texture(names[row], index).get_image()
            atlas.blit_rect(frame_image, Rect2i(Vector2i.ZERO, frame_image.get_size()), Vector2i(index * 256, row * 128))
    atlas.save_png(output.path_join("animations.png"))
    print("PASS: rendered menu, checkpoints, river enemies and death button; " + output)
    quit()
