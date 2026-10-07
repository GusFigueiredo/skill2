extends "res://scripts/Enemy.gd"

const FlameTrail = preload("res://scripts/FlameTrail.gd")
const Fireball = preload("res://scripts/Fireball.gd")

enum State { PURSUIT, WINDUP, CHARGE, RECOVERY, MINOR_ATTACK, FIREBALL }

@export var charge_warning: float = 1.0
@export var charge_cooldown: float = 3.5
@export var charge_speed: float = 700.0
@export var charge_distance: float = 585.0
@export var charge_trigger_distance: float = 220.0
@export var charge_recovery: float = 0.9
@export var charge_damage: int = 5
@export var minor_damage: int = 3
@export var minor_cooldown: float = 1.0
@export var minor_attack_duration: float = 1.0
@export var fireball_distance: float = 200.0
@export var fireball_interval: float = 2.0
@export var fireball_damage: int = 2

var state: State = State.PURSUIT
var state_timer: float = 0.0
var charge_cooldown_timer: float = 0.0
var minor_cooldown_timer: float = 0.0
var fireball_timer: float = 2.0
var fireball_elapsed: float = 0.0
var fireball_fps: float = 6.0
var fireball_released: bool = false
var dash_effect_timer: float = 0.0
var home_bounds := Rect2()
var charge_vector := Vector2.LEFT
var charge_remaining: float = 0.0
var charge_hit: bool = false
var minor_kind: String = ""
var pressure_hits: int = 0
var pressure_timer: float = 0.0
var body_color: Color
var charge_trail: Node2D
var sound_effects := preload("res://scripts/SoundEffects.gd").new()

func _ready() -> void:
	is_boss = true
	super._ready()
	add_child(sound_effects)
	sound_effects.setup({
		"dash": "res://soundeffect/Boitata/Dash.wav",
		"bite": "res://soundeffect/Boitata/Ataque.wav",
		"fireball": "res://soundeffect/Boitata/Bola de fogo.wav",
	}, {"bite": 6.8, "fireball": 1.0})
	body_color = $Sprite.modulate
	# Keep the boss on the connected stretch of road where she spawned.
	home_bounds = Rect2(40, 340, 3720, 220)
	for pit in get_parent().pits:
		if pit.end.x <= global_position.x:
			var right_edge: float = home_bounds.end.x
			home_bounds.position.x = maxf(home_bounds.position.x, pit.end.x + 20.0)
			home_bounds.size.x = right_edge - home_bounds.position.x
		elif pit.position.x > global_position.x:
			home_bounds.size.x = minf(home_bounds.end.x, pit.position.x - 20.0) - home_bounds.position.x

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if not is_instance_valid(player):
			return
	if player.hp <= 0 or get_parent().finished:
		velocity = Vector2.ZERO
		return
	charge_cooldown_timer = maxf(0.0, charge_cooldown_timer - delta)
	minor_cooldown_timer = maxf(0.0, minor_cooldown_timer - delta)
	if global_position.distance_to(player.global_position) > fireball_distance:
		fireball_timer = maxf(0.0, fireball_timer - delta)
	else:
		fireball_timer = fireball_interval
	pressure_timer = maxf(0.0, pressure_timer - delta)
	if pressure_timer <= 0.0:
		pressure_hits = 0
	state_timer = maxf(0.0, state_timer - delta)
	velocity = Vector2.ZERO
	match state:
		State.PURSUIT:
			_pursue()
		State.WINDUP:
			if state_timer <= 0.0:
				preload("res://scripts/CombatVFX.gd").spawn(self, "ring", global_position, Vector2.RIGHT, Color("ffbd56"), 90.0)
				state = State.CHARGE
				sound_effects.play_effect("dash")
				charge_remaining = charge_distance
				charge_hit = false
				dash_effect_timer = 0.0
				# The charge passes through the player; damage respects roll invulnerability.
				collision_mask = 1
		State.CHARGE:
			_update_charge(delta)
		State.RECOVERY:
			if state_timer <= 0.0:
				state = State.PURSUIT
		State.MINOR_ATTACK:
			if state_timer <= 0.0:
				_release_minor()
		State.FIREBALL:
			_update_fireball(delta)
	if state == State.PURSUIT:
		move_and_slide()
		_clamp_position()
	_update_visuals()
	if health_bar:
		health_bar.value = hp
	queue_redraw()

func _pursue() -> void:
	var offset := player.global_position - global_position
	if offset.length() > fireball_distance and fireball_timer <= 0.0:
		direction = 1 if offset.x >= 0.0 else -1
		state = State.FIREBALL
		fireball_elapsed = 0.0
		fireball_released = false
		fireball_fps = $Sprite.sprite_frames.get_animation_speed("fireball")
		$Sprite.play("fireball")
		$Sprite.set_frame_and_progress(0, 0.0)
		$Sprite.pause()
		return
	if charge_cooldown_timer <= 0.0 and offset.length() <= charge_trigger_distance:
		charge_vector = offset.normalized() if offset.length_squared() > 0.0 else Vector2(direction, 0)
		direction = 1 if charge_vector.x >= 0.0 else -1
		state = State.WINDUP
		state_timer = charge_warning
		return
	if charge_cooldown_timer > 0.0 and minor_cooldown_timer <= 0.0:
		if pressure_hits >= 2 and offset.length() < 75.0:
			_start_minor("push", minor_attack_duration)
			return
		if absf(offset.y) < 27.5:
			if offset.x * direction < 0.0 and absf(offset.x) < 90.0:
				_start_minor("tail", minor_attack_duration)
				return
			if offset.x * direction >= 0.0 and absf(offset.x) < 100.0:
				_start_minor("bite", minor_attack_duration)
				return
	if absf(offset.x) > 8.0:
		direction = 1 if offset.x > 0.0 else -1
	velocity = offset.normalized() * speed

func _update_charge(delta: float) -> void:
	dash_effect_timer -= delta
	if dash_effect_timer <= 0.0:
		preload("res://scripts/CombatVFX.gd").afterimage(self, Color(1.0, 0.45, 0.08, 0.5))
		preload("res://scripts/CombatVFX.gd").spawn(self, "dash", global_position + Vector2(0, -20), charge_vector, Color("ffb43d"), 95.0)
		dash_effect_timer = 0.05
	if not is_instance_valid(charge_trail):
		charge_trail = FlameTrail.new()
		charge_trail.player = player
		charge_trail.game_manager = get_parent()
		get_parent().add_child(charge_trail)
	var previous := global_position
	var step := minf(charge_remaining, charge_speed * delta)
	velocity = charge_vector * step / maxf(delta, 0.001)
	move_and_slide()
	_clamp_position()
	var travelled := global_position - previous
	charge_trail.add_segment(previous, global_position)
	# Sweep the path to detect hits even when a frame crosses the player's body.
	var fraction := 0.0
	if travelled.length_squared() > 0.0:
		fraction = clampf((player.global_position - previous).dot(travelled) / travelled.length_squared(), 0.0, 1.0)
	var closest := previous + travelled * fraction
	if not charge_hit and _charge_hits_player(closest):
		charge_hit = player.take_damage(charge_damage)
	charge_remaining -= step
	if charge_remaining <= 0.0 or travelled.length() < step * 0.5:
		charge_trail.emitting = false
		charge_trail = null
		collision_mask = 3
		velocity = Vector2.ZERO
		preload("res://scripts/CombatVFX.gd").spawn(self, "smoke", global_position, charge_vector, Color("ffb86b"), 70.0)
		state = State.RECOVERY
		state_timer = charge_recovery
		charge_cooldown_timer = charge_cooldown
		pressure_hits = 0

func _fireball_mouth_position() -> Vector2:
	# Fire pose is grounded on the same 256x128 canvas as the idle poses.
	return $Sprite.global_position + Vector2(direction * 37.0, 1.0) * $Sprite.scale

func _update_fireball(delta: float) -> void:
	fireball_elapsed += delta
	if not fireball_released and fireball_elapsed >= 1.0 / fireball_fps:
		fireball_released = true
		var mouth := _fireball_mouth_position()
		var projectile = Fireball.new()
		projectile.player = player
		projectile.game_manager = get_parent()
		projectile.damage = fireball_damage
		projectile.travel_direction = (player.global_position - mouth).normalized()
		get_parent().add_child(projectile)
		projectile.global_position = mouth
		preload("res://scripts/CombatVFX.gd").spawn(self, "ring", mouth, projectile.travel_direction, Color("ffc16a"), 24.0)
		sound_effects.play_effect("fireball")
	if fireball_elapsed >= 3.0 / fireball_fps:
		fireball_timer = fireball_interval
		state = State.PURSUIT

func _start_minor(kind: String, warning: float) -> void:
	minor_kind = kind
	state = State.MINOR_ATTACK
	state_timer = warning
	velocity = Vector2.ZERO

func _minor_rect() -> Rect2:
	var facing := -direction if minor_kind == "tail" else direction
	var reach := maxf(90.0 if minor_kind == "tail" else 100.0, combat_bounds.size.x * 0.85)
	return Rect2(Vector2(0.0 if facing > 0 else -reach, -27.5), Vector2(reach, 55.0))

func _release_minor() -> void:
	var effect := "ring" if minor_kind == "push" else "slash"
	var heading := -direction if minor_kind == "tail" else direction
	preload("res://scripts/CombatVFX.gd").spawn(self, effect, global_position + Vector2(0, 0 if minor_kind == "push" else combat_bounds.get_center().y), Vector2(heading, 0), Color("ffae42"), 75.0 if minor_kind == "push" else _minor_rect().size.x)
	if minor_kind == "bite":
		sound_effects.play_effect("bite")
	var offset := player.global_position - global_position
	var in_range := offset.length() <= 75.0 if minor_kind == "push" else _minor_rect().intersects(Rect2(offset - player.get_node("CollisionShape2D").shape.size * 0.5, player.get_node("CollisionShape2D").shape.size))
	if in_range and player.take_damage(minor_damage) and minor_kind == "push":
		var away := offset.normalized() if offset.length_squared() > 0.0 else Vector2(direction, 0)
		# Sweep knockback with normal collisions, then check the floor along its path.
		var previous := player.position
		player.move_and_collide(away * 45.0)
		player._clamp_to_arena()
		get_parent().check_player_floor(previous)
	minor_cooldown_timer = minor_cooldown
	pressure_hits = 0
	state = State.RECOVERY
	state_timer = 0.3

func take_damage(amount: int) -> void:
	if amount > 0:
		pressure_hits += 1
		pressure_timer = 2.5
	super.take_damage(amount)

func _clamp_position() -> void:
	var bounds: Rect2 = get_parent().arena_bounds
	global_position = global_position.clamp(bounds.position, bounds.end)
	global_position = global_position.clamp(home_bounds.position, home_bounds.end)

func _update_visuals() -> void:
	$Sprite.modulate = body_color
	if state == State.WINDUP:
		var progress := 1.0 - state_timer / maxf(charge_warning, 0.001)
		$Sprite.modulate = body_color.lerp(Color(1.0, 0.7, 0.15), 0.4 + progress * 0.6)
	elif state == State.CHARGE:
		$Sprite.modulate = Color(1.0, 0.35, 0.05)
	elif state == State.RECOVERY:
		$Sprite.modulate = body_color.darkened(0.3)

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.3))
	draw_circle(Vector2.ZERO, 16, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	if state == State.WINDUP or state == State.CHARGE:
		draw_set_transform(Vector2.ZERO, charge_vector.angle())
		var lane := Rect2(0, -27.5, charge_distance if state == State.WINDUP else charge_remaining, 55)
		preload("res://scripts/CombatVFX.gd").warning(self, lane, clampf(1.0 - state_timer / maxf(charge_warning, 0.001), 0.0, 1.0), Color("ffb62e"))
		draw_set_transform(Vector2.ZERO)
		draw_circle(Vector2(direction * 10, -43), 4, Color(1, 0.95, 0.4))
		draw_circle(Vector2(direction * 10, -34), 3, Color(1, 0.75, 0.1))
	elif state == State.MINOR_ATTACK:
		if minor_kind == "push":
			draw_circle(Vector2.ZERO, 75, Color(1, 0.65, 0.1, 0.3))
			var progress := clampf(1.0 - state_timer / maxf(minor_attack_duration, 0.001), 0.0, 1.0)
			draw_arc(Vector2.ZERO, 75, -PI * 0.5, -PI * 0.5 + TAU * progress, 48, Color("ffcd67"), 3.0, true)
		else:
			preload("res://scripts/CombatVFX.gd").warning(self, _minor_rect(), clampf(1.0 - state_timer / maxf(minor_attack_duration, 0.001), 0.0, 1.0), Color("ffb62e"))

func _charge_hits_player(closest: Vector2) -> bool:
	var boss_size: Vector2 = $CollisionShape2D.shape.size
	var player_size: Vector2 = player.get_node("CollisionShape2D").shape.size
	var half := (boss_size + player_size) * 0.5
	var offset := (player.global_position - closest).abs()
	return offset.x <= half.x and offset.y <= half.y
