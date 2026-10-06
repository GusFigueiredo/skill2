extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func frames(count: int) -> void:
    for i in count:
        await physics_frame

func run_checks() -> void:
    var scene = load("res://main.tscn").instantiate()
    root.add_child(scene)
    var player = scene.get_node("Player")
    var enemy = scene.get_node("Enemy1")
    scene.get_node("Enemy2").queue_free()
    player.max_hp = 100
    player.hp = 100
    player.global_position = Vector2(300, 458)
    var contact_distance: float = (player.get_node("CollisionShape2D").shape.size.x + enemy.get_node("CollisionShape2D").shape.size.x) * 0.5 + 0.2
    enemy.global_position = Vector2(player.global_position.x + contact_distance, 460)
    enemy.speed = 0.0
    enemy.telegraphed_attacks = false
    enemy.max_hp = 100
    enemy.hp = 100
    await frames(10)
    assert(player.hp == 99, "Touch must deal one immediate hit")
    await frames(30)
    assert(player.hp == 99, "Contact must respect 0.7-second cooldown")
    await frames(10)
    assert(player.hp == 98, "Continuous contact must repeat damage")
    enemy.global_position.x = 600
    await frames(70)
    assert(player.hp == 98, "Separated enemy must stop dealing damage")
    enemy.global_position.x = player.global_position.x + contact_distance
    var start_x = player.global_position.x
    player._start_dodge(1.0)
    var hp_before = player.hp
    assert(not player.take_damage(1), "Dodge must reject damage")
    await frames(10)
    assert(player.hp == hp_before, "Crossing enemy must cause no damage")
    assert(player.sprite.animation == "dodge" and player.sprite.frame > 0, "Roll must display animated dodge poses")
    await frames(8)
    assert(not player.is_dodging, "Dodge must end")
    assert(abs(player.global_position.x - start_x - 120.0) < 1.0, "Roll must travel 120 pixels through enemy")
    assert(player.global_position.x > enemy.global_position.x, "Roll must cross enemy")
    assert(player.sprite.rotation == 0.0, "Roll must restore sprite rotation")
    assert(player.get_collision_exceptions().is_empty() and enemy.get_collision_exceptions().is_empty(), "Roll must restore solid collision")
    assert(player.take_damage(1), "Damage must resume immediately after roll")
    assert(player.hp == hp_before - 1, "Post-roll damage must lower health")
    enemy.global_position.x = player.global_position.x + contact_distance
    await frames(50)
    assert(player.hp == hp_before - 2, "Contact must resume after roll")
    Input.action_press("ui_right")
    await frames(20)
    Input.action_release("ui_right")
    assert(enemy.global_position.x - player.global_position.x >= contact_distance - 0.5, "Solid collision must resume after roll")
    enemy.global_position.x = player.global_position.x + 64
    await frames(2)
    player.facing = 1
    player._attack()
    assert(enemy.hp == 99, "Increased attack reach must hit enemy at 64px")
    player._attack()
    assert(enemy.hp == 99, "Attack must respect cooldown")
    await frames(65)
    player._attack()
    assert(enemy.hp == 98, "Attack must become available after 1 second")
    enemy.global_position.y = player.global_position.y + 80
    await frames(2)
    player.attack_cooldown_timer = 0.0
    var enemy_hp = enemy.hp
    player._attack()
    assert(enemy.hp == enemy_hp, "Attacks must not hit a different depth lane")
    var start_y = player.position.y
    Input.action_press("ui_up")
    await frames(10)
    Input.action_release("ui_up")
    assert(player.position.y < start_y - 20, "Player must move in depth")
    player.global_position = Vector2(300, 430)
    player.can_dodge = true
    Input.action_press("ui_up")
    player._start_dodge(0.0)
    player.dodge_vector = Vector2.UP
    await frames(18)
    Input.action_release("ui_up")
    assert(player.position.y >= 340, "Roll must respect arena boundary")
    assert(not player.is_dodging, "Boundary must not prevent roll from ending")
    enemy.queue_free()
    await frames(3)
    assert(scene.arena_bounds.end.x == 2300, "First wave must open road")
    player.position = Vector2(1030, 430)
    player.last_safe_position = player.position
    var hp_before_pit = player.hp
    player.jump_speed = -player.jump_velocity
    Input.action_press("ui_right")
    await frames(50)
    Input.action_release("ui_right")
    assert(not player.is_falling and player.position.x > 1180, "Jump must cross pit and land on far side")
    assert(player.hp == hp_before_pit, "Successful jump must not deal damage")
    player.position.x = 1510
    await frames(3)
    assert(scene.wave_index == 1 and scene.get_node("Enemy3").visible, "Second wave must activate")
    scene.get_node("Enemy3").queue_free()
    scene.get_node("Enemy4").queue_free()
    await frames(3)
    player.position = Vector2(2420, 430)
    player.last_safe_position = player.position
    player.jump_speed = -player.jump_velocity
    Input.action_press("ui_right")
    await frames(50)
    Input.action_release("ui_right")
    assert(not player.is_falling and player.position.x > 2580, "Second wider pit must be jumpable")
    player.position.x = 2910
    await frames(3)
    assert(scene.wave_index == 2 and scene.boss.visible, "Boss wave must activate")
    scene.boss.take_damage(100)
    await frames(3)
    assert(scene.finished and scene.death_screen.visible, "Boss defeat must end the stage")
    scene.queue_free()
    await frames(2)
    for use_dodge in [false, true]:
        var pit_scene = load("res://main.tscn").instantiate()
        root.add_child(pit_scene)
        var pit_player = pit_scene.get_node("Player")
        pit_scene.arena_bounds.size.x = 2300
        pit_player.position = Vector2(1030, 430)
        pit_player.damage_cooldown = 10.0
        if use_dodge:
            pit_player._start_dodge(1)
        else:
            Input.action_press("ui_right")
        await frames(12)
        Input.action_release("ui_right")
        assert(pit_player.hp == 0 and pit_scene.death_screen.visible, "Pit must kill immediately even during dodge or damage cooldown")
        var fall_position = pit_player.position
        await frames(30)
        assert(not pit_player.visible and not pit_player.is_physics_processing(), "Death must finish fall animation and stop movement")
        assert(pit_player.position == fall_position, "Pit death must not respawn player")
        assert(pit_player.get_collision_exceptions().is_empty(), "Pit death must clear dodge collision exceptions")
        pit_scene.queue_free()
        await frames(2)
    var tutorial_scene = load("res://main.tscn").instantiate()
    root.add_child(tutorial_scene)
    var tutorial_player = tutorial_scene.get_node("Player")
    var attacker = tutorial_scene.get_node("Enemy1")
    assert(not tutorial_scene.get_node("Enemy2").visible, "Tutorial must begin with one enemy")
    tutorial_player.position = Vector2(350, 430)
    tutorial_player.has_moved = true
    attacker.position = Vector2(430, 430)
    attacker.speed = 0.0
    attacker.attack_cooldown_timer = 0.0
    await frames(3)
    assert(attacker.attack_pending, "Enemy must announce attack before dealing damage")
    await frames(20)
    assert(tutorial_player.hp == 10, "Warning must give player time to react")
    await frames(25)
    assert(tutorial_player.hp == 9 and attacker.recovery_timer > 0, "Announced strike must hit and leave recovery window")
    tutorial_player.damage_cooldown = 0.0
    tutorial_player.can_dodge = true
    tutorial_player._start_dodge(1)
    attacker._release_attack()
    assert(tutorial_player.hp == 9, "Roll must negate announced strike")
    tutorial_player._end_dodge()
    tutorial_player.position.y = 510
    attacker._release_attack()
    assert(tutorial_player.hp == 9, "Changing depth must avoid announced strike")
    attacker.take_damage(100)
    await frames(3)
    assert(tutorial_scene.get_node("Enemy2").visible, "Second tutorial enemy must activate after first dies")
    assert(tutorial_scene.get_node("HUD/TutorialLabel").text.contains("ROLADA"), "Tutorial must explain roll at second enemy")
    assert(tutorial_scene.get_node("HUD/CooldownLabel").text.contains("Shift"), "HUD must show roll availability")
    tutorial_scene.queue_free()
    await frames(2)
    print("PASS: combat, roll, jumping both pits, wave progression, instant pit death walking and rolling")
    quit()
