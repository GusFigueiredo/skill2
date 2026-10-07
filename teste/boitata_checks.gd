extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
		assert(condition, message)

func run_checks() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	scene.arena_bounds = Rect2(2800, 340, 960, 220)
	for character in get_nodes_in_group("enemy"):
		character.set_physics_process(false)
	var boss = scene.get_node("Boss")
	check(boss.charge_distance == 585.0, "Charge distance must increase from 360 to 585 pixels")
	check(boss.minor_cooldown == 1.0, "Normal attack cooldown must be 1.0 seconds")
	check(boss.minor_attack_duration == 1.0, "Normal attack hitbox must last 1.0 seconds")
	var player = scene.get_node("Player")
	player.set_physics_process(false)
	boss.player = player
	boss.position = Vector2(3200, 430)
	player.position = Vector2(3500, 510)
	boss._physics_process(0.016)
	check(boss.velocity.x > 0 and boss.velocity.y > 0, "Pursuit must move horizontally and in depth")
	player.position = boss.position + Vector2(180, 0)
	boss._physics_process(0.016)
	check(boss.state == boss.State.WINDUP, "Entering range must start warning")
	var locked_direction: Vector2 = boss.charge_vector
	var warning_position: Vector2 = boss.position
	player.position.y = 540
	boss._physics_process(0.5)
	check(boss.state == boss.State.WINDUP and boss.position == warning_position, "Warning must stop pursuit for one second")
	boss._physics_process(0.51)
	check(boss.state == boss.State.CHARGE and boss.charge_vector == locked_direction, "Charge must lock the original direction")
	var hp_before: int = player.hp
	for index in 50:
		boss._physics_process(0.016)
	check(player.hp == hp_before, "Changing depth must avoid charge")
	check(boss.state == boss.State.RECOVERY, "Missed charge must open recovery window")
	check(boss.charge_cooldown == 3.5 and boss.charge_cooldown_timer > 3.0 and boss.charge_cooldown_timer <= 3.5, "Charge must start 3.5-second cooldown")
	check(boss.collision_mask == 3, "Charge must restore solid collisions")
	boss._physics_process(0.91)
	check(boss.state == boss.State.PURSUIT, "Recovery must return to pursuit")
	player.position = boss.position + Vector2(150, 60)
	boss._physics_process(0.016)
	check(boss.state == boss.State.PURSUIT, "Cooldown must prevent another charge")
	boss.charge_cooldown_timer = 0.0
	player.position = boss.position + Vector2(150, 0)
	boss._physics_process(0.016)
	check(boss.state == boss.State.WINDUP, "Charge must become available after cooldown")
	# A long physics step must still detect a player crossed by the charge.
	boss.position = Vector2(3200, 430)
	player.position = Vector2(3350, 430)
	boss.state = boss.State.CHARGE
	boss.charge_vector = Vector2.RIGHT
	boss.charge_remaining = 360.0
	boss.charge_hit = false
	boss.collision_mask = 1
	boss.charge_speed = 14000.0
	player.damage_cooldown = 0.0
	for trail in get_nodes_in_group("flame_trails"):
		trail.free()
	await physics_frame
	boss._physics_process(1.0 / 60.0)
	check(player.hp == hp_before - 5, "Swept charge must deal five damage")
	boss.position = Vector2(3200, 430)
	player.position = Vector2(3300, 430)
	boss.charge_remaining = 360.0
	boss.charge_hit = false
	player.damage_cooldown = 0.0
	player._start_dodge(1.0)
	await physics_frame
	boss._physics_process(1.0 / 60.0)
	check(player.hp == hp_before - 5, "Roll invulnerability must negate charge")
	boss.charge_speed = 700.0
	player._end_dodge()
	boss.collision_mask = 3
	for trail in get_nodes_in_group("flame_trails"):
		trail.free()
	for kind in ["bite", "tail", "push"]:
		player.hp = 10
		boss.state = boss.State.PURSUIT
		boss.charge_cooldown_timer = boss.charge_cooldown
		boss.minor_cooldown_timer = 0.0
		boss.direction = 1
		boss.position = Vector2(3200, 430)
		player.position = Vector2(3140 if kind == "tail" else 3260, 430)
		player.damage_cooldown = 0.0
		boss.pressure_hits = 2 if kind == "push" else 0
		boss.pressure_timer = 2.5
		await physics_frame
		boss._physics_process(0.016)
		check(boss.state == boss.State.MINOR_ATTACK and boss.minor_kind == kind, "Cooldown must select " + kind)
		var health: int = player.hp
		var previous: Vector2 = player.position
		boss._physics_process(boss.minor_attack_duration + 0.01)
		check(player.hp == health - 3, "Minor attacks must deal three damage")
		if kind == "push":
			check(player.position.x > previous.x, "Body push must knock the player away")
		check(boss.state == boss.State.RECOVERY, "Minor attacks must leave brief recovery")
	boss.pressure_hits = 0
	boss.take_damage(1)
	boss.take_damage(1)
	check(boss.pressure_hits == 2, "Repeated hits must build body-push pressure")
	var trail = load("res://scripts/FlameTrail.gd").new()
	trail.player = player
	trail.game_manager = scene
	scene.add_child(trail)
	trail.set_physics_process(false)
	trail.emitting = false
	trail.add_segment(Vector2(3000, 430), Vector2(3200, 430))
	player.position = Vector2(3100, 430)
	player.hp = 10
	player.damage_cooldown = 0.0
	trail._physics_process(0.01)
	check(player.hp == 9, "Touching burning trail must deal one damage immediately")
	player.damage_cooldown = 0.0
	trail._physics_process(0.5)
	check(player.hp == 9, "Fire must not repeat damage before one second")
	player.position.y = 510
	trail._physics_process(0.1)
	player.position.y = 430
	trail._physics_process(0.1)
	check(player.hp == 9, "Re-entering or overlapping segments must not bypass fire cooldown")
	trail._physics_process(0.31)
	check(player.hp == 8, "Remaining in fire must deal another point after one second")
	player.damage_cooldown = 0.0
	trail._physics_process(0.49)
	check(trail.segments.is_empty() and player.hp == 8, "Fire must expire at 1.5 seconds and stop damage")
	var roll_trail = load("res://scripts/FlameTrail.gd").new()
	roll_trail.player = player
	roll_trail.game_manager = scene
	scene.add_child(roll_trail)
	roll_trail.set_physics_process(false)
	roll_trail.add_segment(Vector2(3000, 430), Vector2(3200, 430))
	player.can_dodge = true
	player._start_dodge(1.0)
	roll_trail._physics_process(0.1)
	check(player.hp == 8, "Rolling through the trail must reject fire damage")
	player._end_dodge()
	roll_trail._physics_process(0.1)
	check(player.hp == 7, "Fire must damage again after roll ends")
	roll_trail.add_segment(Vector2(3200, 430), Vector2(3400, 430))
	player.position.y = 540
	roll_trail._physics_process(1.31)
	check(roll_trail.segments.size() == 1, "Each trail segment must retain its own 1.5-second lifetime")
	player.hp = 10
	player.damage_cooldown = 0.0
	boss.position = Vector2(2600, 430)
	player.position = Vector2(2200, 430)
	scene.arena_bounds = Rect2(40, 340, 3720, 220)
	boss.state = boss.State.CHARGE
	boss.charge_vector = Vector2.LEFT
	boss.charge_remaining = 585.0
	boss.charge_hit = false
	boss.collision_mask = 1
	boss._physics_process(0.5)
	check(boss.position.x >= 2580.0, "Charge must stop before the last pit, even with a long physics step")
	check(boss.state == boss.State.RECOVERY and boss.collision_mask == 3, "Blocked charge must recover and restore collisions")
	boss.state = boss.State.PURSUIT
	boss.fireball_timer = boss.fireball_interval
	check(boss.fireball_distance == 200.0 and boss.fireball_interval == 2.0, "Fireballs must use 200px range and two-second cooldown")
	boss._physics_process(1.99)
	check(get_nodes_in_group("fireballs").is_empty(), "Distant attack must wait two seconds")
	boss._physics_process(0.02)
	check(boss.state == boss.State.FIREBALL, "Distant player must begin the cast after two seconds")
	check(get_nodes_in_group("fireballs").is_empty(), "First cast frame must not emit a projectile")
	boss._physics_process(1.0 / boss.fireball_fps + 0.001)
	check(get_nodes_in_group("fireballs").size() == 1, "Second cast frame must emit one projectile")
	var mouth: Vector2 = boss._fireball_mouth_position()
	check(get_nodes_in_group("fireballs")[0].global_position.is_equal_approx(mouth), "Projectile must originate at the mouth")
	boss.get_node("Sprite")._process(0.0)
	check(boss.get_node("Sprite").animation == "fireball" and boss.get_node("Sprite").frame == 1, "Projectile release must match the second frame")
	boss._physics_process(1.0 / boss.fireball_fps)
	boss.get_node("Sprite")._process(0.0)
	check(boss.get_node("Sprite").frame == 2, "Cast must return to its first pose before idle")
	check(get_nodes_in_group("fireballs").size() == 1, "Fireballs must respect cooldown")
	boss._physics_process(1.0 / boss.fireball_fps)
	boss.get_node("Sprite")._process(0.0)
	check(boss.state == boss.State.PURSUIT and boss.get_node("Sprite").animation == "idle", "Cast must return to idle after 1-2-1")
	var projectile = get_nodes_in_group("fireballs")[0]
	projectile.set_physics_process(false)
	projectile._physics_process(0.09)
	check(projectile.get_node("Sprite").flip_v, "Projectile must alternate vertical flip")
	projectile._physics_process(2.0)
	check(player.hp == 8, "Fireball must sweep its path and deal two damage")
	await process_frame
	var dodge_projectile = load("res://scripts/Fireball.gd").new()
	dodge_projectile.player = player
	dodge_projectile.game_manager = scene
	dodge_projectile.travel_direction = Vector2.LEFT
	scene.add_child(dodge_projectile)
	dodge_projectile.set_physics_process(false)
	dodge_projectile.position = player.position + Vector2(100, 0)
	player.damage_cooldown = 0.0
	player.can_dodge = true
	player._start_dodge(1.0)
	dodge_projectile._physics_process(0.5)
	check(player.hp == 8, "Roll must negate fireball damage")
	print("PASS: Boitata attacks, pit boundary, ranged cooldown, projectile damage and roll immunity")
	scene.queue_free()
	quit(0)
