extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func run_checks() -> void:
    var tutorial = load("res://main.tscn").instantiate()
    root.add_child(tutorial)
    tutorial.set_process(false)
    assert(tutorial.tutorial_stage)
    for scenery in [tutorial.get_node("Background"), tutorial.get_node("Ground")]:
        assert(scenery.position.x <= -1000)
        assert(scenery.position.x + scenery.region_rect.size.x * scenery.scale.x > 4800)
        assert(scenery.position.y + scenery.region_rect.size.y * scenery.scale.y >= 1999)
        assert(scenery.material.shader != null)
    assert(tutorial.get_node("Background").position.y <= -1000)
    assert(tutorial.pits.size() == 1)
    assert(tutorial.waves.size() == 1)
    assert(tutorial.waves[0].size() == 2)
    tutorial.free()
    var level = load("res://ratanaba2.tscn").instantiate()
    root.add_child(level)
    level.set_process(false)
    assert(not level.tutorial_stage)
    assert(level.tutorial.step == level.tutorial.Step.COMPLETE)
    assert(level.waves[0].size() == 2)
    assert(level.waves[1].size() == 3)
    assert(level.waves[2] == [level.boss])
    assert(level.pits.size() == 1 and level.pits[0].position.x == 2450)
    var bar = level.health_bar
    bar.value = bar.max_value
    bar.value -= 2
    assert(bar.damage_segments.size() == 1)
    bar._process(0.4)
    assert(bar.damage_segments.size() == 1)
    bar._process(0.5)
    assert(bar.damage_segments.is_empty())
    for actor in get_nodes_in_group("enemy") + get_nodes_in_group("player"):
        actor.set_physics_process(false)
    level.wave_index = 1
    for enemy in level.waves[1]:
        enemy.hp = 0
    level.player.position = Vector2(2700, 430)
    level.player.jump_height = 20.0
    level._process(0.016)
    assert(level.music.playing and not level.boss_area_entered)
    level.player.jump_height = 0.0
    level._process(0.016)
    assert(not level.music.playing and level.boss_area_entered)
    assert(level.boss_intro_running)
    assert(not level.boss.visible, "Boss stays hidden during the 20-pixel entry walk")
    assert(not level.player.is_physics_processing())
    assert(level.player.sprite.animation == "walk")
    level.boss_entry_tween.custom_step(0.2)
    assert(is_equal_approx(level.player.position.x, 2720.0))
    assert(level.player.sprite.animation == "idle")
    assert(not level.player.sprite.is_processing())
    assert(not level.music.playing)
    assert(not level.boss.is_physics_processing())
    var camera = get_root().get_camera_2d()
    var view_width: float = get_root().get_visible_rect().size.x / camera.zoom.x
    var right_of_view: float = camera.global_position.x + view_width * 0.5
    assert(level.boss.position.x + 0.01 >= level.boss_landing_position.x + view_width + 20.0)
    assert(level.boss.position.x + level.boss.combat_bounds.position.x > right_of_view, "Entire boss must spawn offscreen")
    var visual = level.boss.get_node("Sprite")
    assert(visual.animation == "idle" and visual.modulate.r < 0.4)
    assert(not level.get_node("HUD/BossHealth").visible)
    var start_x: float = get_root().get_camera_2d().global_position.x
    var intro = level.boss_intro_tween
    intro.custom_step(0.9)
    assert(get_root().get_camera_2d().global_position.x > start_x)
    assert(visual.animation == "idle" and visual.modulate.r < 0.4)
    intro.custom_step(1.51)
    assert(visual.animation == "bite" and visual.frame == 0)
    assert(visual.modulate == level.boss.body_color)
    assert(not level.music.playing and not level.boss.is_physics_processing())
    var roar = load("res://soundeffect/Boitata/rujido.mp3")
    intro.custom_step(roar.get_length())
    assert(visual.animation == "idle")
    intro.custom_step(0.2)
    assert(level.boss_intro_running and not level.music.playing)
    intro.custom_step(0.31)
    assert(not level.boss_intro_running)
    assert(level.player.is_physics_processing())
    assert(level.boss.is_physics_processing())
    assert(level.music.playing)
    assert(level.music.stream is AudioStreamMP3)
    level.free()
    print("PASS: tutorial, 2/3/boss encounters, pit placement, damage fade and boss introduction")
    quit()
