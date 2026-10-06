extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	for actor in get_nodes_in_group("enemy") + get_nodes_in_group("player"):
		actor.set_physics_process(false)
	assert(scene.health_bar.frame_kind == "player")
	assert(scene.get_node("Enemy1/HealthBar").frame_kind == "enemy")
	assert(scene.get_node("Boss/HealthBar").frame_kind == "boss")
	assert(scene.get_node("HUD/BossHealth").frame_kind == "boss")
	scene.player.take_damage(4)
	scene._update_hud()
	assert(is_equal_approx(scene.health_bar.get_fill_ratio(), 0.6))
	scene.get_node("Enemy1").take_damage(1)
	assert(is_equal_approx(scene.get_node("Enemy1/HealthBar").get_fill_ratio(), 2.0 / 3.0))
	scene.boss.take_damage(3)
	scene._update_hud()
	assert(is_equal_approx(scene.get_node("Boss/HealthBar").get_fill_ratio(), 0.5))
	assert(is_equal_approx(scene.get_node("HUD/BossHealth").get_fill_ratio(), 0.5))
	for bar in [scene.health_bar, scene.get_node("Enemy1/HealthBar"), scene.get_node("HUD/BossHealth")]:
		bar.value = 0
		assert(bar.get_fill_ratio() == 0)
		assert(bar.get_node("Frame").visible, "The frame must remain at zero health")
	print("PASS: correct health frames, damage proportions and persistent frame at zero health")
	scene.free()
	quit()
