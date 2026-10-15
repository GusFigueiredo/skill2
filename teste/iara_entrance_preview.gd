extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    create_timer(30.0, true).timeout.connect(func(): quit(1))
    var output := ProjectSettings.globalize_path("res://.validation")
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
    var boss_arrival: float = intro.PLAYER_ZOOM_SECONDS + intro.PLAYER_HOLD_SECONDS + intro.IARA_TRAVEL_SECONDS
    var kiss_start: float = boss_arrival + intro.IARA_HOLD_SECONDS
    var return_start: float = kiss_start + intro.kiss_seconds + intro.laugh_seconds + intro.END_HOLD_SECONDS
    var stages := {
        "player": intro.PLAYER_ZOOM_SECONDS + 0.05,
        "pan": intro.PLAYER_ZOOM_SECONDS + intro.PLAYER_HOLD_SECONDS + intro.IARA_TRAVEL_SECONDS * 0.5,
        "iara": boss_arrival + intro.IARA_HOLD_SECONDS * 0.5,
        "kiss": kiss_start + intro.kiss_seconds * 0.85,
        "laugh": kiss_start + intro.kiss_seconds + intro.laugh_seconds * 0.65,
        "hold": return_start - intro.END_HOLD_SECONDS * 0.5,
        "gameplay": return_start + intro.RETURN_SECONDS + 0.05,
    }
    var elapsed := 0.0
    for stage: String in stages:
        intro.sequence.custom_step(stages[stage] - elapsed)
        elapsed = stages[stage]
        fight.player.set_physics_process(false)
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        view.get_texture().get_image().save_png(output.path_join("polish-iara-" + stage + ".png"))
    fight.free()
    view.free()
    print("PASS: Iara player closeup, boss closeup, kiss, laugh and return captured; " + output)
    quit()
