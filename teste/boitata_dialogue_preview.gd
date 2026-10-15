extends SceneTree

func _initialize() -> void:
    call_deferred("preview")

func preview() -> void:
    create_timer(25.0, true).timeout.connect(func(): quit(1))
    root.size = Vector2i(1280, 720)
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
    fight.player.get_node("Camera2D").reset_smoothing()
    fight.player.get_node("Camera2D").force_update_scroll()
    fight.boss.take_damage(100)
    await create_timer(2.2).timeout
    var conversation = fight.get_node("BoitataDialogue")
    var box = conversation.dialogue
    await create_timer(0.3).timeout
    for page in range(box.pages.size()):
        box.advance()
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://.validation/polish-boitata-dialogue-%d.png" % (page + 1))
        if page + 1 < box.pages.size():
            box.advance()
    while conversation.line_index == 0:
        box.advance()
        await process_frame
    await create_timer(0.3).timeout
    box.advance()
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://.validation/polish-boitata-player-dialogue.png")
    quit()
