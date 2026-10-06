extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	for actor in get_nodes_in_group("enemy") + get_nodes_in_group("player"):
		actor.set_physics_process(false)
	var player = scene.player
	player.position = Vector2(200, 430)
	var shift := InputEventKey.new()
	shift.keycode = KEY_SHIFT
	shift.pressed = true
	player.jump_height = 30.0
	player._input(shift)
	assert(not player.is_dodging and player.can_dodge and player.dodge_cooldown_timer == 0.0, "Shift during a jump must not start dodge or consume cooldown")
	player._start_dodge(1.0)
	assert(not player.is_dodging, "Direct dodge requests must also be blocked in midair")
	player.jump_height = 0.0
	player.jump_speed = 120.0
	player._input(shift)
	assert(not player.is_dodging, "Dodge must be blocked at takeoff before height increases")
	player.jump_speed = 0.0
	player._input(shift)
	assert(player.is_dodging and player.sprite.animation == "dodge", "Shift must activate protection immediately")
	var health: int = player.hp
	assert(not player.take_damage(2), "Damage on the input frame must be rejected")
	var flame = load("res://scripts/FlameTrail.gd").new()
	flame.player = player
	flame.game_manager = scene
	scene.add_child(flame)
	flame.set_physics_process(false)
	flame.add_segment(player.position - Vector2(50, 0), player.position + Vector2(200, 0))
	flame._physics_process(0.01)
	assert(player.hp == health, "Ground fire must respect dodge protection")
	var projectile = load("res://scripts/Fireball.gd").new()
	projectile.player = player
	projectile.game_manager = scene
	scene.add_child(projectile)
	projectile.set_physics_process(false)
	projectile.position = player.position
	projectile._physics_process(0.01)
	assert(player.hp == health, "Projectiles must respect dodge protection")
	player._update_dodge(player.dodge_duration)
	assert(not player.is_dodging)
	assert(not player.take_damage(3), "The final dodge physics frame must stay protected")
	await physics_frame
	assert(player.take_damage(1), "Damage must resume on the next physics frame")
	assert(player.hp == health - 1)
	scene.free()
	print("PASS: instant Shift protection, fire, projectiles and final dodge frame")
	quit()
