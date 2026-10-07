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
	player.position = Vector2(800, 430)
	enemy.position = Vector2(840, 430)
	await physics_frame
	await physics_frame
	var hp_before: int = enemy.hp
	player._attack()
	assert(enemy.hp == hp_before - player.attack_damage)
	assert(player.sprite.animation == "attack" and player.sprite.frame == 1, "Punch pose must coincide with damage")
	assert(player.sprite.sprite_frames.get_animation_speed("attack") == 20.0)
	player.attack_cooldown_timer -= 0.11
	player.sprite._process(0.11)
	assert(player.sprite.animation == "idle", "Fast attack must finish without holding the last pose")
	var projectile = load("res://scripts/Fireball.gd").new()
	projectile.player = player
	projectile.game_manager = scene
	projectile.travel_direction = Vector2.RIGHT
	scene.add_child(projectile)
	projectile.set_physics_process(false)
	var body := player.get_node("HurtArea").get_child(0) as CollisionShape2D
	projectile.position = body.global_position + Vector2(70, 0)
	assert(projectile.hitbox.shape.size == Vector2(projectile.FIREBALL_TEXTURE.get_image().get_used_rect().size))
	assert(projectile._swept_hits_player(projectile.position), "Visible flame tail must hit even beyond the old 24px radius")
	projectile.position.y += body.shape.size.y * 0.5 + projectile.hitbox.shape.size.y * 0.25 + 5.0
	assert(not projectile._swept_hits_player(projectile.position), "Clear space outside the new sprite must not hit")
	projectile.position = body.global_position + Vector2(200, 0)
	assert(projectile._swept_hits_player(body.global_position - Vector2(200, 0)), "A long step across the body must still hit")
	print("PASS: immediate punch pose, faster recovery, sprite-sized fireball tail, outside miss and swept collision")
	scene.free()
	quit()
