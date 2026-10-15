extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func run_checks() -> void:
    create_timer(15.0, true).timeout.connect(func(): quit(1))
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
    var original_zoom := original.zoom
    fight._start_boss_intro()
    var timeline: Tween = fight.boss_intro_tween
    timeline.pause()
    var camera := root.get_camera_2d()
    var visual := fight.boss.get_node("Sprite") as AnimatedSprite2D
    var flames := fight.get_node("BoitataIntroFlames") as Node2D
    var overlay: CanvasLayer
    var roar: AudioStreamPlayer
    for child in fight.get_children():
        if child is AudioStreamPlayer and child.stream == preload("res://soundeffect/Boitata/rujido.mp3"):
            roar = child
        elif child is CanvasLayer and child.get_script() == preload("res://scripts/BossEntrance.gd"):
            overlay = child
    assert(camera != original and fight.boss_intro_running)
    assert(not fight.player.is_physics_processing() and not fight.boss.is_physics_processing())
    assert(not fight.get_node("HUD").visible, "The cinematic must hide gameplay bars and checkpoint notices")
    assert(camera.limit_top == original.limit_top and camera.limit_bottom == original.limit_bottom, "Boitata's close-up must stay within the drawn stage")
    timeline.custom_step(fight.BOSS_APPROACH_SECONDS + fight.BOSS_REVEAL_SECONDS - 0.01)
    assert(camera.zoom.x > original_zoom.x and visual.animation == "idle" and not roar.playing, "The shaded idle close-up must precede the roar")
    assert(flames.strength > 0.5 and overlay.title_label.text == "BOITATÁ", "Fire must build around the silhouette as the guardian's name appears")
    camera.force_update_scroll()
    var stage_size := root.get_visible_rect().size
    var body_on_screen := Rect2((fight.boss.global_position + fight.boss.combat_bounds.position - camera.get_screen_center_position()) * camera.zoom + stage_size * 0.5, fight.boss.combat_bounds.size * camera.zoom)
    assert(body_on_screen.position.x > 0.0 and body_on_screen.end.x < stage_size.x, "The composed shot must keep the full boss inside the picture")
    assert(body_on_screen.position.y > 44.0 and body_on_screen.end.y < stage_size.y - 44.0, "Letterbox bars must leave her head and base visible")
    var reveal_zoom := camera.zoom
    timeline.custom_step(0.02)
    assert(roar.playing and visual.animation == "bite", "The entrance must play the supplied full roar with the bite pose")
    var roar_seconds := roar.stream.get_length()
    timeline.custom_step(roar_seconds * 0.25)
    assert(camera.offset.length() < 5.0, "The roar shake must stay small enough to read the character")
    assert(camera.zoom.x > reveal_zoom.x, "The roar shot must continue a gentle push instead of freezing the camera")
    paused = true
    var frozen_position := camera.global_position
    var frozen_zoom := camera.zoom
    timeline.play()
    await create_timer(0.1, true).timeout
    assert(camera.global_position == frozen_position and camera.zoom == frozen_zoom, "Pause must freeze the entrance camera")
    timeline.pause()
    paused = false
    timeline.custom_step(roar_seconds * 0.75 - 0.03)
    assert(fight.boss_intro_running and not fight.player.is_physics_processing(), "Gameplay must wait for the entire roar interval")
    timeline.custom_step(0.04)
    assert(camera.offset == Vector2.ZERO and visual.animation == "idle")
    timeline.custom_step(fight.AFTER_ROAR_SECONDS - 0.03)
    assert(fight.boss_intro_running, "The smooth return must retain its half-second duration")
    timeline.custom_step(0.04)
    assert(not fight.boss_intro_running and original.is_current() and original.zoom == original_zoom)
    assert(fight.player.is_physics_processing() and fight.boss.is_physics_processing())
    assert(fight.get_node("HUD").visible, "The gameplay HUD must return with control")
    assert(fight.music.playing, "The battle track must begin when the cinematic restores control")
    print("PASS: Boitata composed full-body reveal, building flames/name, hidden HUD, full roar, gentle push/shake, pause and playable return")
    fight.queue_free()
    await process_frame
    quit()
