extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	for actor in get_nodes_in_group("enemy") + get_nodes_in_group("player"):
		actor.set_physics_process(false)
		actor.get_node("Sprite").set_process(false)
	var player = scene.get_node("Player")
	var enemy = scene.get_node("Enemy1")
	enemy.spawn_finished = true
	scene._set_enemy_active(enemy, true)
	enemy.set_physics_process(false)
	player.position = Vector2(800, 430)
	enemy.hp = 100
	for heading in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		player.facing = -1 if heading.x < 0 else 1
		player._update_attack_direction(heading)
		player._update_attack_direction(Vector2.ZERO)
		assert(player._attack_heading() == heading, "Direction must persist after releasing movement")
		enemy.position = player.position + heading * 64.0
		await physics_frame
		await physics_frame
		var health: int = enemy.hp
		player.attack_cooldown_timer = 0.0
		player._attack()
		assert(enemy.hp == health - player.attack_damage, "Strike must hit in direction %s" % heading)
		var effect: Node2D
		for child in scene.get_children():
			if child.get_script() == load("res://scripts/CombatVFX.gd") and child.kind == "slash":
				effect = child
		assert(effect != null, "Strike must spawn its visual effect")
		assert(effect.kind == "slash")
		assert(Vector2.RIGHT.rotated(effect.rotation).is_equal_approx(heading), "Slash must follow damage direction")
		enemy.position = player.position - heading * 100.0
		await physics_frame
		await physics_frame
		health = enemy.hp
		player.attack_cooldown_timer = 0.0
		player._attack()
		assert(enemy.hp == health, "Strike must not hit behind the chosen direction")
	print("PASS: four attack directions, matching slash effects, remembered direction and opposite-side misses")
	scene.free()
	quit()
