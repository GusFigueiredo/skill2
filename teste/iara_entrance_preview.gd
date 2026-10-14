extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    create_timer(30.0, true).timeout.connect(func(): quit(1))
    var output := OS.get_environment("TEMP").path_join("skill2-iara-entrance-previews")
    DirAccess.make_dir_recursive_absolute(output)
    var view := SubViewport.new()
    view.size = Vector2i(1280, 720)
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var fight = load("res://rio_negro4.tscn").instantiate()
    view.add_child(fight)
    preload("res://iara_test_support.gd").reach_boss(fight)
    fight.set_process(false)
    fight.set_physics_process(false)
    var intro = fight.entrance
    intro.sequence.pause()
    intro.letterbox.elapsed = 1.0
    var stages := {
        "player": 0.65,
        "iara": 3.25,
        "kiss": 3.6 + intro.kiss_seconds * 0.85,
        "laugh": 3.6 + intro.kiss_seconds + intro.laugh_seconds * 0.65,
        "gameplay": 3.6 + intro.kiss_seconds + intro.laugh_seconds + intro.END_HOLD_SECONDS + 0.55,
    }
    var elapsed := 0.0
    for stage: String in stages:
        intro.sequence.custom_step(stages[stage] - elapsed)
        elapsed = stages[stage]
        fight.player.set_physics_process(false)
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        view.get_texture().get_image().save_png(output.path_join(stage + ".png"))
    fight.free()
    view.free()
    print("PASS: Iara player closeup, boss closeup, kiss, laugh and return captured; " + output)
    quit()
