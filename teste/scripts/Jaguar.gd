extends "res://scripts/Enemy.gd"

## The bush is scenery. Only a committed pounce makes the jaguar a hittable enemy.
enum State { HIDDEN, RUSTLE, AMBUSH, GRAPPLE, RECOVERY, PURSUE, TELL, STRIKE, LEAP, DEAD }

const FRAMES := preload("res://scripts/JaguarFrames.gd")
const VFX := preload("res://scripts/CombatVFX.gd")
const AMBUSH_RANGE := Vector2(225.0, 165.0)
const RUSTLE_SECONDS := 0.82
const AMBUSH_SECONDS := 0.68

var state: State = State.HIDDEN
var state_timer := 0.0
var active := false
var ambush_used := false
var grappled := false
var attack_kind := "paw"
var attack_number := 0
var attack_hit := false
var bush: Node2D
var bush_visual_borrowed := false
var bush_original_alpha := 1.0
var bush_original_speed := 1.0
var emerge_started := false
var sprite_ground := Vector2.ZERO
var leap_start := Vector2.ZERO
var leap_target := Vector2.ZERO
var leap_height := 0.0
var leap_duration := 0.65
var state_duration := 0.0
var recovery_push := Vector2.ZERO
var recovery_start := Vector2.ZERO
var hurt_flash := 0.0
var clock := 0.0
var dust_timer := 0.0
var leaves: Array[Dictionary] = []
var visual: AnimatedSprite2D
var sounds := preload("res://scripts/SoundEffects.gd").new()

func _ready() -> void:
	visual = $Sprite as AnimatedSprite2D
	visual.sprite_frames = FRAMES.build(142.0)
	visual.position = FRAMES.grounded_offset(visual.sprite_frames)
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite_ground = visual.position
	max_hp = 5
	speed = 156.0
	attack_damage = 1
	super._ready()
	health_bar.position = Vector2(-58, -104)
	health_bar.size = Vector2(116, 20)
	damage_area.monitoring = false
	spawn_finished = true
	spawn_started = true
	_play("idle")
	add_child(sounds)
	sounds.setup({
		"pounce": "res://soundeffect/Personagem/dodge.wav",
		"swipe": "res://soundeffect/Personagem/ataque.wav",
		"land": "res://soundeffect/Feedback/hit.wav",
	}, {"pounce": -4.0, "swipe": -6.0, "land": -8.0})
	(sounds.players["pounce"] as AudioStreamPlayer).pitch_scale = 1.2
	(sounds.players["swipe"] as AudioStreamPlayer).pitch_scale = 0.85
	_set_body_enabled(false)
	visible = false
	set_physics_process(false)

func configure_ambush(point: Vector2, source_bush: Node2D) -> void:
	_restore_bush()
	position = point
	bush = source_bush
	state = State.HIDDEN
	ambush_used = false
	grappled = false
	visible = false
	if is_node_ready():
		_set_body_enabled(false)

func play_spawn_animation(on_finished: Callable) -> void:
	# Never reverse the death animation: the living animal waits in the undergrowth.
	spawn_started = true
	spawn_finished = true
	set_encounter_active(true)
	if on_finished.is_valid():
		on_finished.call()

func set_encounter_active(enabled: bool) -> void:
	active = enabled
	set_physics_process(enabled)
	if not is_node_ready():
		return
	var exposed := enabled and state not in [State.HIDDEN, State.RUSTLE, State.GRAPPLE, State.DEAD]
	visible = enabled and state != State.HIDDEN
	health_bar.visible = exposed
	_set_body_enabled(exposed)
	if not enabled:
		velocity = Vector2.ZERO
		_restore_bush()

func _physics_process(delta: float) -> void:
	if not active or hp <= 0:
		return
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not is_instance_valid(player):
		return
	clock += delta
	_update_leaves(delta)
	hurt_flash = maxf(0.0, hurt_flash - delta)
	visual.modulate = Color(1.0, 0.66, 0.5) if hurt_flash > 0.0 else Color.WHITE
	if player.hp <= 0 or get_parent().get("finished") == true:
		_restore_bush()
		if grappled:
			abort_grapple()
		velocity = Vector2.ZERO
		return
	state_timer += delta
	attack_cooldown_timer = maxf(0.0, attack_cooldown_timer - delta)
	match state:
		State.HIDDEN:
			_watch_ambush()
		State.RUSTLE:
			_rustle()
		State.AMBUSH, State.LEAP:
			_update_leap()
		State.GRAPPLE:
			velocity = Vector2.ZERO
		State.RECOVERY:
			_update_recovery()
		State.PURSUE:
			_pursue(delta)
		State.TELL:
			_update_tell()
		State.STRIKE:
			_update_strike(delta)
	health_bar.value = hp
	queue_redraw()

func _watch_ambush() -> void:
	var offset := player.global_position - global_position
	if absf(offset.x) > AMBUSH_RANGE.x or absf(offset.y) > AMBUSH_RANGE.y:
		return
	if player.is_falling or player.control_locked:
		return
	direction = -1 if offset.x < 0.0 else 1
	visual.flip_h = direction < 0
	_change_state(State.RUSTLE, RUSTLE_SECONDS)
	emerge_started = false
	_borrow_bush()
	_bush_animation("bush_reveal")
	if bush is AnimatedSprite2D:
		# Three eye-reveal frames fit before the animal emerges from the foliage.
		bush.speed_scale = 1.65
	_scatter_leaves(14)

func _rustle() -> void:
	if state_timer >= 0.24 and not emerge_started:
		emerge_started = true
		visible = true
		health_bar.hide()
		_play("emerge", true)
	if emerge_started and is_instance_valid(bush):
		_borrow_bush()
		# Emergence frames already contain this same plant.
		bush.modulate.a = 0.0
	if state_timer >= RUSTLE_SECONDS:
		ambush_used = true
		_restore_bush()
		_bush_animation("bush_idle")
		_scatter_leaves(20)
		_begin_leap(true)

func _begin_leap(is_ambush: bool) -> void:
	leap_start = global_position
	var offset := player.global_position - leap_start
	# The opening pounce guarantees the struggle; later leaps commit to a spot.
	leap_target = player.global_position if is_ambush else _safe_point(leap_start + offset.limit_length(290.0))
	direction = -1 if leap_target.x < leap_start.x else 1
	attack_direction = direction
	visual.flip_h = direction < 0
	leap_duration = AMBUSH_SECONDS if is_ambush else 0.65
	attack_hit = false
	_change_state(State.AMBUSH if is_ambush else State.LEAP, leap_duration)
	_set_body_enabled(false)
	get_node("HurtArea").collision_layer = 0 if is_ambush else 8
	health_bar.show()
	_play("leap", true)
	sounds.play_effect("pounce")
	VFX.spawn(self, "smoke", global_position, Vector2(direction, 0), Color("b7b783"), 35.0)

func _update_leap() -> void:
	var progress := clampf(state_timer / leap_duration, 0.0, 1.0)
	var curve := smoothstep(0.0, 1.0, progress)
	if state == State.AMBUSH:
		# Follow the player throughout the first arc, including a dodge or jump.
		# Do not clamp this contact to the animal's smaller roaming boundaries.
		leap_target = player.global_position
	global_position = leap_start.lerp(leap_target, curve)
	leap_height = sin(progress * PI) * (94.0 if state == State.AMBUSH else 72.0)
	_update_hurt_height()
	visual.position = sprite_ground - Vector2(0, leap_height)
	visual.rotation = direction * lerpf(-0.11, 0.13, progress)
	if state_timer < leap_duration:
		return
	var was_ambush := state == State.AMBUSH
	leap_height = 0.0
	visual.position = sprite_ground
	visual.rotation = 0.0
	_set_body_enabled(true)
	_land_effects()
	if was_ambush and _can_pin_player() and get_parent().has_method("begin_jaguar_grapple"):
		if get_parent().begin_jaguar_grapple(self):
			grappled = true
			_change_state(State.GRAPPLE)
			_set_body_enabled(false)
			health_bar.hide()
			_play("struggle", true)
			return
	if not was_ambush:
		_hit_player(Vector2(82.0, 52.0))
	_start_recovery(0.85 if was_ambush else 0.7)

func _can_pin_player() -> bool:
	var offset := player.global_position - global_position
	return absf(offset.x) <= 90.0 and absf(offset.y) <= 56.0 \
		and player.hp > 0 and not player.is_falling and not player.control_locked

func finish_grapple(success: bool) -> void:
	if hp <= 0:
		return
	grappled = false
	leap_height = 0.0
	visual.position = sprite_ground
	visual.rotation = 0.0
	visual.scale = Vector2.ONE
	visible = true
	_set_body_enabled(active)
	health_bar.visible = active
	var away := global_position - player.global_position if is_instance_valid(player) else Vector2(-direction, 0)
	if away.length() < 15.0:
		away = Vector2(-direction, 0)
	recovery_start = global_position
	recovery_push = _safe_point(global_position + away.normalized() * (145.0 if success else 105.0)) - global_position
	_start_recovery(1.2 if success else 0.9, true)
	_land_effects()

func abort_grapple() -> void:
	_restore_bush()
	grappled = false
	leap_height = 0.0
	if not is_instance_valid(visual):
		return
	visual.position = sprite_ground
	visual.rotation = 0.0
	visual.scale = Vector2.ONE
	_set_body_enabled(active and hp > 0)
	health_bar.visible = active and hp > 0
	_start_recovery(0.8)

func _start_recovery(seconds: float, preserve_push: bool = false) -> void:
	leap_height = 0.0
	visual.position = sprite_ground
	visual.rotation = 0.0
	visual.scale = Vector2.ONE
	_update_hurt_height()
	if not preserve_push:
		recovery_push = Vector2.ZERO
		recovery_start = global_position
	_change_state(State.RECOVERY, seconds)
	attack_cooldown_timer = seconds + 0.45
	_play("idle")

func _update_recovery() -> void:
	if recovery_push.length_squared() > 0.1:
		var progress := minf(1.0, state_timer / 0.38)
		var ease := 1.0 - pow(1.0 - progress, 3.0)
		global_position = recovery_start + recovery_push * ease
		visual.rotation = -direction * sin(progress * PI) * 0.2
		visual.position = sprite_ground - Vector2(0, sin(progress * PI) * 25.0)
	if state_timer >= state_duration:
		visual.rotation = 0.0
		visual.position = sprite_ground
		recovery_push = Vector2.ZERO
		_change_state(State.PURSUE)

func _pursue(delta: float) -> void:
	if player.control_locked or get_parent().get("boss_intro_running") == true:
		velocity = Vector2.ZERO
		_play("idle")
		return
	var offset := player.global_position - global_position
	direction = -1 if offset.x < 0 else 1
	visual.flip_h = direction < 0
	var next_attack: String = ["paw", "bite", "leap"][attack_number % 3]
	var range_x := 270.0 if next_attack == "leap" else 99.0
	if attack_cooldown_timer <= 0.0 and absf(offset.x) < range_x and absf(offset.y) < 54.0:
		attack_kind = next_attack
		attack_number += 1
		attack_direction = direction
		attack_hit = false
		_change_state(State.TELL, {"paw": 0.42, "bite": 0.53, "leap": 0.62}[attack_kind])
		_hold_tell_pose(0.0)
		return
	if offset.length() > 78.0:
		_move_ground(offset.normalized() * speed, delta)
		_play("run")
		dust_timer -= delta
		if dust_timer <= 0.0:
			dust_timer = 0.19
			VFX.spawn(self, "smoke", global_position + Vector2(-direction * 28, 0), Vector2.RIGHT, Color(0.55, 0.53, 0.33, 0.32), 14.0)
	else:
		velocity = Vector2.ZERO
		_play("idle")

func _update_tell() -> void:
	velocity = Vector2.ZERO
	var progress := clampf(state_timer / state_duration, 0.0, 1.0)
	_hold_tell_pose(progress)
	if state_timer < state_duration:
		return
	visual.position = sprite_ground
	visual.rotation = 0.0
	visual.scale = Vector2.ONE
	if attack_kind == "leap":
		_begin_leap(false)
	else:
		_change_state(State.STRIKE, 0.32 if attack_kind == "paw" else 0.38)
		_play(attack_kind, true)

func _hold_tell_pose(progress: float) -> void:
	var pose := attack_kind if attack_kind in ["paw", "bite"] else "idle"
	_play(pose)
	visual.set_frame_and_progress(0, 0.0)
	visual.pause()
	match attack_kind:
		"paw":
			# Raise the striking paw and lean away before the sweep.
			visual.position = sprite_ground + Vector2(-attack_direction * 8.0, -4.0) * progress
			visual.rotation = -attack_direction * 0.1 * progress
			visual.scale = Vector2(1.0, 1.0 + progress * 0.025)
		"bite":
			# Lower the head and stretch forward before the short lunge.
			visual.position = sprite_ground + Vector2(attack_direction * 6.0, 4.0) * progress
			visual.rotation = attack_direction * 0.06 * progress
			visual.scale = Vector2(1.0 + progress * 0.035, 1.0 - progress * 0.03)
		_:
			# Compress the hind legs and recoil before committing to a jump.
			visual.position = sprite_ground + Vector2(-attack_direction * 12.0, 9.0) * progress
			visual.rotation = -attack_direction * 0.04 * progress
			visual.scale = Vector2(1.0 + progress * 0.08, 1.0 - progress * 0.15)

func _update_strike(delta: float) -> void:
	var progress := clampf(state_timer / state_duration, 0.0, 1.0)
	if progress < 0.6:
		_move_ground(Vector2(attack_direction * (105.0 if attack_kind == "paw" else 185.0), 0), delta)
	if progress >= 0.35 and not attack_hit:
		attack_hit = true
		var area := _attack_rect()
		sounds.play_effect("swipe")
		VFX.spawn(self, "slash", global_position + Vector2(attack_direction * 35.0, -24), Vector2(attack_direction, 0), Color("ffdc9d"), 58.0 if attack_kind == "paw" else 40.0)
		_hit_player(area.size * Vector2(1.0, 0.65), true)
	if state_timer >= state_duration:
		_start_recovery(0.55 if attack_kind == "paw" else 0.75)

func _hit_player(reach: Vector2, forward: bool = false) -> void:
	if not is_instance_valid(player) or player.hp <= 0 or player.jump_height > 30.0 or player.is_falling:
		return
	var offset := player.global_position - global_position
	var inside := absf(offset.x) <= reach.x and absf(offset.y) <= reach.y
	if forward:
		inside = inside and offset.x * attack_direction >= -28.0
	if inside:
		player.take_damage(attack_damage)

func take_damage(amount: int) -> void:
	if not active or hp <= 0 or amount <= 0 or state in [State.HIDDEN, State.RUSTLE, State.AMBUSH, State.GRAPPLE, State.DEAD]:
		return
	hurt_flash = 0.12
	if hp - amount <= 0:
		_restore_bush()
		state = State.DEAD
		active = false
		grappled = false
		_set_body_enabled(false)
		visual.position = sprite_ground
		visual.rotation = 0.0
		visual.scale = Vector2.ONE
	super.take_damage(amount)

func _update_contact_damage() -> void:
	# Contact is harmless. Only a clearly signalled paw, bite or landing can hit.
	pass

func _attack_rect() -> Rect2:
	var reach := 115.0 if attack_kind == "paw" else 100.0
	return Rect2(Vector2(-25.0 if attack_direction > 0 else -reach, -35.0), Vector2(reach + 25.0, 70.0))

func _set_body_enabled(enabled: bool) -> void:
	collision_layer = 4 if enabled else 0
	collision_mask = 1 | 2 if enabled else 0
	if is_instance_valid(damage_area):
		damage_area.monitoring = false
	var hurt := get_node_or_null("HurtArea") as Area2D
	if hurt:
		hurt.collision_layer = 8 if enabled else 0
		_update_hurt_height()

func _update_hurt_height() -> void:
	var hurt := get_node_or_null("HurtArea") as Area2D
	if hurt and hurt.get_child_count() > 0:
		var shape := hurt.get_child(0) as CollisionShape2D
		shape.position.y = combat_bounds.get_center().y - leap_height

func _safe_point(point: Vector2) -> Vector2:
	var level := get_parent()
	var bounds: Rect2 = level.arena_bounds
	point = point.clamp(bounds.position + Vector2(36, 6), bounds.end - Vector2(36, 6))
	for gap: Rect2 in level.pits:
		var blocked := gap.grow(42.0)
		# The animal never shortcuts across the abyss to reach a moving target.
		if blocked.has_point(point) or (global_position.x < blocked.position.x and point.x > blocked.end.x) or (global_position.x > blocked.end.x and point.x < blocked.position.x):
			point.x = blocked.position.x - 1.0 if global_position.x < gap.get_center().x else blocked.end.x + 1.0
	return point

func _move_ground(step_velocity: Vector2, delta: float) -> void:
	var destination := _safe_point(global_position + step_velocity * delta)
	velocity = (destination - global_position) / maxf(delta, 0.001)
	move_and_slide()
	global_position = _safe_point(global_position)

func _change_state(next: State, duration: float = 0.0) -> void:
	state = next
	state_timer = 0.0
	state_duration = duration
	velocity = Vector2.ZERO

func _play(animation_name: String, restart: bool = false) -> void:
	if not visual.sprite_frames.has_animation(animation_name):
		animation_name = "idle"
	if restart or visual.animation != animation_name or not visual.is_playing():
		visual.play(animation_name)

func _borrow_bush() -> void:
	if not is_instance_valid(bush) or bush_visual_borrowed:
		return
	bush_visual_borrowed = true
	bush_original_alpha = bush.modulate.a
	if bush is AnimatedSprite2D:
		bush_original_speed = bush.speed_scale

func _restore_bush() -> void:
	if not bush_visual_borrowed:
		return
	bush_visual_borrowed = false
	if is_instance_valid(bush):
		bush.modulate.a = bush_original_alpha
		if bush is AnimatedSprite2D:
			bush.speed_scale = bush_original_speed
		_bush_animation("bush_idle")

func _bush_animation(animation_name: String) -> void:
	if not is_instance_valid(bush):
		return
	if bush.has_method("rustle") and animation_name == "bush_rustle":
		bush.rustle()
	elif bush is AnimatedSprite2D and bush.sprite_frames.has_animation(animation_name):
		bush.play(animation_name)

func _land_effects() -> void:
	sounds.play_effect("land")
	VFX.spawn(self, "smoke", global_position, Vector2.RIGHT, Color("b5aa7c"), 40.0)
	VFX.spawn(self, "ring", global_position, Vector2.RIGHT, Color(0.74, 0.73, 0.43, 0.42), 38.0)

func _scatter_leaves(count: int) -> void:
	for index in count:
		leaves.append({"origin": global_position, "point": Vector2(sin(index * 3.31) * 27.0, -18.0), "speed": Vector2(cos(index * 2.399) * (55.0 + index * 2.0), -55.0 - index * 4.0), "age": 0.0, "life": 0.7 + float(index % 4) * 0.12, "angle": index * 2.399})

func _update_leaves(delta: float) -> void:
	for index in range(leaves.size() - 1, -1, -1):
		var leaf: Dictionary = leaves[index]
		leaf.age += delta
		if leaf.age >= leaf.life:
			leaves.remove_at(index)
			continue
		leaf.speed += Vector2(0, 125) * delta
		leaf.point += leaf.speed * delta
		leaf.angle += delta * 7.0

func _draw() -> void:
	if state == State.HIDDEN or state == State.DEAD:
		return
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.3))
	draw_circle(Vector2.ZERO, 38.0 - leap_height * 0.13, Color(0.02, 0.04, 0.01, 0.32 - leap_height * 0.0014))
	draw_set_transform(Vector2.ZERO)
	if state == State.TELL:
		var tint := Color("e9b950") if attack_kind != "leap" else Color("ff9c55")
		VFX.warning(self, _attack_rect(), clampf(state_timer / maxf(state_duration, 0.01), 0.0, 1.0), tint)
	for leaf: Dictionary in leaves:
		var fade: float = 1.0 - leaf.age / leaf.life
		draw_set_transform(to_local(leaf.origin) + leaf.point, leaf.angle)
		draw_colored_polygon(PackedVector2Array([Vector2(-4, 0), Vector2(0, -2), Vector2(5, 0), Vector2(0, 2)]), Color(0.42, 0.55, 0.15, fade))
	draw_set_transform(Vector2.ZERO)
