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
    preload("res://iara_test_support.gd").reach_boss(fight)
    fight.entrance.finish()
    fight.set_physics_process(false)
    fight.set_process(false)
    fight.player.set_physics_process(false)
    fight.player.sprite.set_process(false)
    fight.boss.set_physics_process(false)
    fight.boss.hide()
    var camera: Camera2D = fight.player.get_node("Camera2D")
    camera.position_smoothing_enabled = false
    fight.player.position = fight.boss_point(Vector2(760, 460))
    camera.reset_smoothing()
    fight.state = fight.State.IDLE
    fight.state_timer = 20.0
    for exposure in [0.0, 1.5, 2.99]:
        fight.water_exposure = exposure
        fight._set_submersion(exposure / fight.DROWNING_SECONDS)
        if not await capture_frame(view, "exposure-%s" % str(exposure).replace(".", "-")):
            fight.free()
            view.free()
            quit()
            return
    fight.water_exposure = 0.0
    fight._restore_water_visual()
    fight._begin_drowning()
    await capture_frame(view, "fatal-start")
    fight._physics_process(1.5)
    await capture_frame(view, "fatal-half")
    fight._physics_process(1.51)
    await capture_frame(view, "death-start")
    fight._update_sinking_corpse(0.8)
    fight.river_effects.death_elapsed = 0.8
    await capture_frame(view, "corpse-half")
    fight._update_sinking_corpse(1.1)
    fight.river_effects.death_elapsed = 1.8
    await capture_frame(view, "corpse-hidden")
    fight.free()
    view.free()
    print("PASS: Submersion previews captured")
    quit()

func capture_frame(view: SubViewport, phase: String) -> bool:
    await process_frame
    await process_frame
    await process_frame
    if RenderingServer.get_video_adapter_name() != "":
        await RenderingServer.frame_post_draw
    var rendered := view.get_texture().get_image()
    if rendered == null or rendered.is_empty():
        print("NO_RENDER: headless viewport produced no image. Display: %s; adapter: %s" % [DisplayServer.get_name(), RenderingServer.get_video_adapter_name()])
        return false
    var saved := rendered.save_png("res://iara-submersion-%s-preview.png" % phase)
    print("CAPTURE: %s (%s)" % [phase, saved])
    return saved == OK
