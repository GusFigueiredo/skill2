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
    assert(map.stage_buttons[2].disabled, "Unimplemented stage stays locked")
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
    print("PASS: persistent sequential unlock, launch guard and music during tutorial pause")
    quit()
