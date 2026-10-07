extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	for actor in get_nodes_in_group("enemy") + get_nodes_in_group("player"):
		actor.set_physics_process(false)
	var player = scene.get_node("Player")
	var enemy = scene.get_node("Enemy1")
	var boss = scene.get_node("Boss")
	assert(player.sprite.scale == Vector2(0.9375, 0.9375))
	assert(enemy.get_node("Sprite").scale == Vector2(0.9375, 0.9375))
	assert(boss.get_node("Sprite").scale == Vector2(1.5, 1.5))
	for actor in [player, enemy, boss]:
		var footprint: Vector2 = actor.get_node("CollisionShape2D").shape.size
		var hurtbox: Vector2 = actor.get_node("HurtArea").get_child(0).shape.size
		assert(footprint.x > 24.0, "Footprints must follow the enlarged sprite width")
		assert(hurtbox.y > footprint.y, "Damage detection must cover the body above the ground")
		if actor != player:
			var bar: ProgressBar = actor.get_node("HealthBar")
			assert(bar.position.y + bar.size.y < actor.combat_bounds.position.y, "Enemy health bars must clear the head")
		var visual: AnimatedSprite2D = actor.get_node("Sprite")
		for animation_name in visual.sprite_frames.get_animation_names():
			assert(visual.sprite_frames.get_frame_count(animation_name) > 0)
			for index in visual.sprite_frames.get_frame_count(animation_name):
				var frame := visual.sprite_frames.get_frame_texture(animation_name, index).get_image()
				assert(frame.get_size() == Vector2i(256, 128))
				assert(frame.get_pixel(0, 0).a == 0.0, "Frames must have transparent margins")
				assert(frame.get_used_rect().has_area(), "No pose may be empty")
	player.velocity = Vector2(100, 0)
	player.sprite._process(0.016)
	assert(player.sprite.animation == "walk")
	player.velocity = Vector2(0, -100)
	player.sprite._process(0.016)
	assert(player.sprite.animation == "walk_up" and not player.sprite.flip_h)
	player.velocity = Vector2(0, 100)
	player.sprite._process(0.016)
	assert(player.sprite.animation == "walk_down")
	player.attack_cooldown_timer = player.attack_cooldown
	player.sprite._process(0.016)
	assert(player.sprite.animation == "attack")
	player.is_dodging = true
	player.sprite._process(0.016)
	assert(player.sprite.animation == "dodge")
	player.is_dodging = false
	player.attack_cooldown_timer = 0
	player.jump_height = 20
	player.sprite._process(0.016)
	assert(player.sprite.animation == "jump")
	enemy.attack_pending = true
	enemy.get_node("Sprite")._process(0.016)
	assert(enemy.get_node("Sprite").animation == "attack")
	boss.state = boss.State.WINDUP
	boss.get_node("Sprite")._process(0.016)
	assert(boss.get_node("Sprite").animation == "windup")
	boss.state = boss.State.CHARGE
	boss.get_node("Sprite")._process(0.016)
	assert(boss.get_node("Sprite").animation == "dash")
	var boss_frames: SpriteFrames = boss.get_node("Sprite").sprite_frames
	assert(boss_frames.get_frame_count("idle") == 4)
	assert(boss_frames.get_frame_count("bite") == 4)
	assert(boss_frames.get_frame_count("dash") == 1)
	assert(boss_frames.get_frame_count("fireball") == 3)
	assert(boss_frames.get_frame_texture("fireball", 0).get_image().get_data() == boss_frames.get_frame_texture("fireball", 2).get_image().get_data())
	boss.state = boss.State.PURSUIT
	boss.velocity = Vector2(100, 0)
	boss.get_node("Sprite")._process(0.016)
	assert(boss.get_node("Sprite").animation == "idle", "Boss movement must use idle")
	print("PASS: transparent frames, character sizes and gameplay animation transitions")
	scene.free()
	quit()
