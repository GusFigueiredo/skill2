extends SceneTree

func _initialize() -> void:
    call_deferred("preview")

func preview() -> void:
    root.size = Vector2i(1280, 720)
    change_scene_to_file("res://rio_negro4.tscn")
    await process_frame
    await process_frame
    var fight = current_scene
    preload("res://iara_test_support.gd").prepare_fight(fight)
    fight.boss.hp = 3
    fight.on_iara_damaged()
    fight.boss.hp = 1
    fight.on_iara_damaged()
    fight._physics_process(fight.state_timer + 0.01)
    fight._physics_process(fight.CAST_SECONDS + 0.01)
    fight.player.position = fight.WATER_POSITION + Vector2(30, 0)
    fight._physics_process(0.01)
    fight._physics_process(fight.DROWNING_SECONDS * 0.91)
    var rescue = fight.get_node("VitoriaRescue")
    while not rescue.waiting:
        await process_frame
    rescue.dialogue.advance()
    rescue.dialogue.advance()
    while not rescue.waiting:
        await process_frame
    rescue.dialogue.advance()
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://.validation/vitoria-shared-leaf-preview.png")
    quit()
