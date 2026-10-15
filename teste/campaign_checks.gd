extends SceneTree

const Progress = preload("res://scripts/CampaignProgress.gd")

func _initialize() -> void:
    call_deferred("run_checks")

func run_checks() -> void:
    assert(Progress.completed_stages() == 0, "Run in isolated fresh APPDATA")
    var map = load("res://level_map.tscn").instantiate()
    root.add_child(map)
    assert(not map.stage_buttons[0].disabled)
    assert(map.stage_buttons[1].disabled)
    map._show_stage(1)
    assert(map.start_button.disabled)
    map._start_selected_stage()
    assert(not map.transitioning)
    Progress.complete_stage(1)
    assert(Progress.completed_stages() == 0, "Cannot skip predecessor")
    Progress.complete_stage(0)
    assert(Progress.completed_stages() == 1)
    assert(Progress.is_available(1))
    map.free()
    map = load("res://level_map.tscn").instantiate()
    root.add_child(map)
    assert(not map.stage_buttons[1].disabled)
    map._show_stage(1)
    assert(not map.start_button.disabled)
    assert(map.stage_buttons[2].disabled, "The next stage stays locked until its predecessor is complete")
    map.free()
    var level = load("res://main.tscn").instantiate()
    root.add_child(level)
    level.set_process(false)
    var guide = level.tutorial
    guide.step = guide.Step.ATTACK
    guide.lesson_enemy = level.waves[0][0]
    assert(guide.intercept_attack(guide.lesson_enemy))
    assert(paused and level.music.process_mode == Node.PROCESS_MODE_ALWAYS)
    assert(level.music.playing)
    var playback: float = level.music.get_playback_position()
    await create_timer(0.25, true).timeout
    assert(level.music.get_playback_position() > playback, "Music clock must advance during tutorial pause")
    paused = false
    level.free()
    for index in range(1, 4):
        Progress.complete_stage(index)
    assert(Progress.completed_stages() == 4 and Progress.is_available(4), "Iara's defeat must unlock phase five")
    assert(Progress.stage_path(4) == "res://floresta5.tscn" and ResourceLoader.exists(Progress.stage_path(4)), "Phase five must resolve to the forest scene")
    assert(not Progress.is_available(5) and Progress.stage_path(5).is_empty(), "Phase six must stay unavailable until implemented")
    map = load("res://level_map.tscn").instantiate()
    root.add_child(map)
    assert(not map.stage_buttons[4].disabled and map.stage_buttons[5].disabled)
    map._show_stage(4)
    assert(not map.start_button.disabled and "Floresta" in map.details_label.text, "The unlocked forest must be selectable on the map")
    map.free()
    for checkpoint_id in ["start", "trecho_2", "trecho_3", "caverna"]:
        Progress.save_checkpoint(4, checkpoint_id, Vector2(640, 460))
        assert(Progress.checkpoint().get("stage", -1) == 4 and Progress.checkpoint().get("id", "") == checkpoint_id, "Every forest section must accept its own checkpoint")
    Progress.save_checkpoint(4, "wave_2", Vector2(640, 460))
    assert(Progress.checkpoint().is_empty(), "Phase five must reject checkpoint IDs from other stages")
    Progress.save_checkpoint(4, "caverna", Vector2(640, 460))
    Progress.complete_stage(4)
    assert(Progress.completed_stages() == 5 and Progress.checkpoint().is_empty(), "Finishing the forest must persist completion and clear its checkpoint")
    assert(not Progress.is_available(5), "Completing phase five must not expose an unimplemented cave")
    print("PASS: sequential unlock through the forest, forest checkpoint validation, unavailable phase six, launch guard and music during tutorial pause")
    quit()
