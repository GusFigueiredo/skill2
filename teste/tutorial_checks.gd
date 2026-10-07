extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	for actor in get_nodes_in_group("player") + get_nodes_in_group("enemy"):
		actor.set_physics_process(false)
	var guide = scene.tutorial
	var hero = scene.player
	var enemy = scene.waves[0][0]
	assert(guide.step == guide.Step.WALK and not enemy.visible and not paused)
	assert(not scene.get_node("HUD/TutorialLabel").visible)
	hero.position.x += 110.0
	guide.advance(0.1)
	assert(guide.reward_timer == 0.0)
	hero.position.x += 140.0
	guide.advance(0.1)
	assert(is_equal_approx(guide.reward_timer, 2.5))
	guide.advance(1.0)
	assert(guide.step == guide.Step.WALK)
	guide.advance(1.6)
	assert(guide.step == guide.Step.DODGE and not paused)
	hero.has_dodged = true
	hero.is_dodging = true
	guide.advance(0.1)
	assert(guide.reward_timer == 0.0)
	hero.is_dodging = false
	guide.advance(0.1)
	guide.advance(2.6)
	assert(guide.step == guide.Step.JUMP and not paused)
	hero.has_jumped = true
	hero.jump_height = 20.0
	guide.advance(0.1)
	assert(guide.reward_timer == 0.0)
	hero.jump_height = 0.0
	hero.jump_speed = 0.0
	guide.advance(0.1)
	guide.advance(2.6)
	assert(guide.step == guide.Step.ATTACK and guide.introducing_enemy)
	assert(not paused and not guide.visible)
	assert(enemy.visible and not enemy.is_physics_processing())
	assert(enemy.collision_layer == 0 and enemy.get_node("HurtArea").collision_layer == 0)
	assert(is_equal_approx(enemy.position.distance_to(hero.position), 260.0))
	assert(enemy.get_node("Sprite").animation == "death")
	assert(enemy.get_node("Sprite").frame == enemy.get_node("Sprite").sprite_frames.get_frame_count("death") - 1)
	var position_before: Vector2 = hero.position
	for x in [scene.arena_bounds.position.x, scene.arena_bounds.end.x, scene.arena_bounds.get_center().x]:
		hero.position.x = x
		var spawn: Vector2 = guide._enemy_spawn_position()
		assert(spawn.x >= scene.arena_bounds.position.x and spawn.x <= scene.arena_bounds.end.x)
		assert(is_equal_approx(spawn.distance_to(hero.position), 260.0))
	hero.position = position_before
	for tick in range(50):
		if not guide.introducing_enemy:
			break
		guide.arrival_tween.custom_step(0.1)
	assert(not guide.introducing_enemy and guide.visible and not paused)
	assert(hero.get_node("Camera2D").is_current())
	assert(enemy.is_physics_processing() and enemy.collision_layer == 4)
	assert(enemy.get_node("Sprite").animation == "idle")
	enemy.set_physics_process(false)
	hero.has_attacked = true
	guide.advance(0.1)
	assert(guide.reward_timer == 0.0)
	enemy.take_damage(1)
	guide.advance(0.1)
	assert(guide.reward_timer == 0.0)
	enemy.player = hero
	enemy.position = hero.position + Vector2(60, 0)
	enemy.attack_pending = true
	enemy.attack_direction = -1
	enemy.attack_timer = 0.1
	assert(guide.intercept_attack(enemy) and paused and guide.waiting_for_dodge)
	assert(hero.sprite.animation == "idle" and hero.velocity == Vector2.ZERO)
	assert(hero.facing == 1 and guide.cinematic_camera.is_current())
	var shift := InputEventKey.new()
	shift.keycode = KEY_SHIFT
	shift.pressed = true
	guide._input(shift)
	assert(paused, "Wait for the camera to finish approaching")
	guide.dodge_camera_tween.custom_step(0.7)
	assert(guide.dodge_zoom_ready)
	# Rolling outside the warning area must count without crossing the enemy.
	enemy.position = hero.position + Vector2(200, 0)
	var health: int = hero.hp
	guide._input(shift)
	assert(guide.combat_dodge_done and hero.hp == health and not paused)
	assert(hero.is_dodging and not enemy.attack_pending and not guide.waiting_for_dodge)
	assert(not guide.intercept_attack(enemy), "Pause only for the first guided dodge")
	guide.dodge_camera_tween.custom_step(0.5)
	assert(hero.get_node("Camera2D").is_current())
	guide.advance(0.1)
	guide.advance(2.6)
	assert(guide.step == guide.Step.COMPLETE and not guide.visible)
	scene.road_open = true
	guide.advance(0.1)
	guide._process(0.1)
	assert(not guide.visible)
	for actor in [scene.get_node("Enemy2"), scene.get_node("Enemy3"), scene.get_node("Enemy4"), scene.boss]:
		scene._set_enemy_active(actor, true)
		assert(actor.visible and actor.spawn_started and not actor.spawn_finished)
		assert(not actor.is_physics_processing() and actor.collision_layer == 0)
		assert(actor.get_node("HurtArea").collision_layer == 0)
		var visual := actor.get_node("Sprite") as AnimatedSprite2D
		if visual.sprite_frames.has_animation("death"):
			assert(visual.animation == "death")
			assert(visual.frame == visual.sprite_frames.get_frame_count("death") - 1)
		actor.spawn_tween.custom_step(2.0)
		assert(actor.spawn_finished and actor.is_physics_processing())
		assert(actor.collision_layer == 4 and visual.animation == "idle")
		actor.set_physics_process(false)
	scene.free()
	print("PASS: guided dodge outside warning area, no damage, animated arrivals for every enemy and restored collisions")
	quit()
