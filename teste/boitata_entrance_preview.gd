extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    create_timer(20.0, true).timeout.connect(func(): quit(1))
    root.size = Vector2i(1280, 720)
    change_scene_to_file("res://ratanaba2.tscn")
    await process_frame
    await process_frame
    var fight = current_scene
    fight.set_process(false)
    for actor in get_nodes_in_group("player") + get_nodes_in_group("enemy"):
        actor.set_physics_process(false)
    fight.boss_area_entered = true
    fight.wave_index = 2
    fight.boss_landing_position = Vector2(2750, 450)
    fight.player.position = fight.boss_landing_position + Vector2(fight.BOSS_ENTRY_WALK_DISTANCE, 0)
    var original := fight.player.get_node("Camera2D") as Camera2D
    original.reset_smoothing()
    original.force_update_scroll()
    fight._start_boss_intro()
    var timeline: Tween = fight.boss_intro_tween
    timeline.pause()
    var overlay: CanvasLayer
    for child in fight.get_children():
        if child is CanvasLayer and child.get_script() == preload("res://scripts/BossEntrance.gd"):
            overlay = child
    var roar_start: float = fight.BOSS_APPROACH_SECONDS + fight.BOSS_REVEAL_SECONDS
    var roar_seconds := preload("res://soundeffect/Boitata/rujido.mp3").get_length()
    var stages := {"approach": fight.BOSS_APPROACH_SECONDS * 0.5, "reveal": fight.BOSS_APPROACH_SECONDS + fight.BOSS_REVEAL_SECONDS * 0.7, "roar": roar_start + 0.35, "settle": roar_start + roar_seconds * 0.8}
    var elapsed := 0.0
    for stage: String in stages:
        timeline.custom_step(stages[stage] - elapsed)
        elapsed = stages[stage]
        # The timeline is stepped manually, so advance the overlay's own art clock too.
        overlay.elapsed = elapsed
        overlay.roar_elapsed = elapsed - roar_start if elapsed >= roar_start else -1.0
        overlay.title_progress = clampf((elapsed - fight.BOSS_APPROACH_SECONDS) / 0.65, 0.0, 1.0)
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://.validation/polish-boitata-" + stage + ".png")
    fight.queue_free()
    await process_frame
    quit()
