extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func run_checks() -> void:
    var level = load("res://main.tscn").instantiate()
    root.add_child(level)
    level.set_process(false)
    for actor in get_nodes_in_group("player") + get_nodes_in_group("enemy"):
        actor.set_physics_process(false)
    var attack = level.get_node("HUD/AttackCooldown")
    var dodge = level.get_node("HUD/DodgeCooldown")
    assert(attack.icon != null and dodge.icon != null)
    assert(attack.ability == "attack" and dodge.ability == "dodge")
    level.player.attack_cooldown_timer = level.player.attack_cooldown * 0.5
    level.player.dodge_cooldown_timer = level.player.dodge_cooldown
    level._update_hud()
    assert(is_equal_approx(attack.value, 50) and dodge.value == 0)
    level.player.attack_cooldown_timer = 0
    level.player.dodge_cooldown_timer = 0
    level._update_hud()
    assert(attack.value == 100 and dodge.value == 100)
    assert(attack.ready_flash > 0 and dodge.ready_flash > 0)
    assert(root.get_visible_rect().encloses(attack.get_global_rect()))
    assert(root.get_visible_rect().encloses(dodge.get_global_rect()))
    var feedback = level.get_node("CombatFeedback")
    var hero = level.player
    var enemy = level.get_node("Enemy1")
    hero.sprite.set_process(true)
    enemy.get_node("Sprite").set_process(true)
    var original_speed: float = hero.sprite.speed_scale
    feedback.hit(enemy)
    assert(hero.sprite.speed_scale == 0)
    assert(not hero.is_physics_processing(), "Presentation must not enable actor physics")
    feedback._process(0.08)
    assert(hero.sprite.speed_scale == original_speed)
    assert(Engine.time_scale == 1, "Feedback must not slow movement, music or cooldowns")
    feedback._process(0.2)
    assert(hero.get_node("Camera2D").offset == Vector2.ZERO)
    hero._start_dodge(1)
    var health: int = hero.hp
    assert(not hero.take_damage(2) and hero.hp == health)
    assert(hero.dodge_rewarded)
    var count: int = level.get_child_count()
    hero.take_damage(2)
    assert(level.get_child_count() == count, "Successful dodge feedback fires once per roll")
    var ambience = level.ambience
    assert(not ambience.forest.playing and not ambience.crackle.playing)
    ambience.begin()
    ambience._process(0.8)
    assert(ambience.forest.playing and ambience.crackle.playing)
    assert(ambience.forest.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD)
    assert(ambience.forest.stream.loop_end == roundi(ambience.forest.stream.get_length() * ambience.forest.stream.mix_rate))
    var full_volume: float = ambience.forest.volume_db
    ambience.duck()
    ambience._process(0.5)
    assert(ambience.forest.volume_db < full_volume)
    ambience.end()
    ambience._process(2)
    assert(not ambience.forest.playing and not ambience.crackle.playing)
    hero._end_dodge()
    hero.can_dodge = true
    hero.attack_cooldown_timer = 0
    level.boss_intro_running = true
    hero._start_dodge(1)
    hero._attack()
    assert(not hero.is_dodging and hero.attack_cooldown_timer == 0, "Cinematics must keep the hero idle")
    level.free()
    await process_frame
    print("PASS: cooldown fill and readiness glow, visual hit pause, camera reset, dodge immunity and one-shot reward, looped ambience duck and fade")
    quit()
