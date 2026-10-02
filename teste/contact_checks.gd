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
    enemy.global_position = Vector2(324, 460)
    enemy.speed = 0.0
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
    enemy.global_position.x = player.global_position.x + 24
    var start_x = player.global_position.x
    player._start_dodge(1.0)
    var hp_before = player.hp
    assert(not player.take_damage(1), "Dodge must reject damage")
    await frames(10)
    assert(player.hp == hp_before, "Crossing enemy must cause no damage")
    assert(abs(player.sprite.rotation) > 0.1, "Roll must visibly rotate")
    await frames(8)
    assert(not player.is_dodging, "Dodge must end")
    assert(abs(player.global_position.x - start_x - 120.0) < 1.0, "Roll must travel 120 pixels through enemy")
    assert(player.global_position.x > enemy.global_position.x, "Roll must cross enemy")
    assert(player.sprite.rotation == 0.0, "Roll must restore sprite rotation")
    assert(player.get_collision_exceptions().is_empty() and enemy.get_collision_exceptions().is_empty(), "Roll must restore solid collision")
    assert(player.take_damage(1), "Damage must resume immediately after roll")
    assert(player.hp == hp_before - 1, "Post-roll damage must lower health")
    enemy.global_position.x = player.global_position.x + 24
    await frames(50)
    assert(player.hp == hp_before - 2, "Contact must resume after roll")
    Input.action_press("ui_right")
    await frames(20)
    Input.action_release("ui_right")
    assert(enemy.global_position.x - player.global_position.x >= 23.5, "Solid collision must resume after roll")
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
    print("PASS: contact, separation, dodge recovery, 120px roll through enemy, restored collision, attack cooldown")
    quit()
