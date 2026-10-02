extends CharacterBody2D

@export var max_hp: int = 3
@export var speed: float = 70.0
@export var attack_damage: int = 1
@export var is_boss: bool = false
@export var contact_damage_interval: float = 0.7

@export var telegraphed_attacks: bool = true
var attack_timer: float = 0.0
var attack_cooldown_timer: float = 1.0
var recovery_timer: float = 0.0
var attack_direction: int = 1
var attack_pending: bool = false
var hp: int
var player: CharacterBody2D
var direction: int = -1
var contact_damage_cooldown: float = 0.0

@onready var health_bar: ProgressBar = $HealthBar
@onready var damage_area: Area2D = $DamageArea

func _ready() -> void:
	hp = max_hp
	motion_mode = MOTION_MODE_FLOATING
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 1 | 2
	if damage_area:
		damage_area.monitoring = true
		damage_area.monitorable = false
		damage_area.collision_layer = 0
		damage_area.collision_mask = 2
		# Extend past the solid body so touching bodies register despite safe_margin.
		var damage_shape := damage_area.get_child(0) as CollisionShape2D
		if damage_shape.shape is RectangleShape2D:
			damage_shape.shape = damage_shape.shape.duplicate()
			damage_shape.shape.size += Vector2(8, 4)
	if is_boss:
		speed = 90.0
		attack_damage = 2
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = hp

func _physics_process(delta: float) -> void:
	if contact_damage_cooldown > 0.0:
		contact_damage_cooldown = max(0.0, contact_damage_cooldown - delta)

	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			return

	queue_redraw()
	attack_cooldown_timer = maxf(0.0, attack_cooldown_timer - delta)
	recovery_timer = maxf(0.0, recovery_timer - delta)
	if player.hp <= 0 or get_parent().finished:
		velocity = Vector2.ZERO
		attack_pending = false
		return
	if attack_pending:
		attack_timer -= delta
		if attack_timer <= 0.0:
			_release_attack()
	var offset := player.global_position - global_position
	direction = -1 if offset.x < 0.0 else 1
	velocity = offset.normalized() * speed if offset.length() < 520.0 and player.hp > 0 else Vector2.ZERO

	if attack_pending or recovery_timer > 0.0:
		velocity = Vector2.ZERO
	elif telegraphed_attacks and attack_cooldown_timer <= 0.0 and absf(offset.x) < 110.0 and absf(offset.y) < 24.0:
		attack_pending = true
		attack_timer = 0.9 if is_boss else 0.65
		attack_direction = direction
		velocity = Vector2.ZERO
	move_and_slide()
	var bounds: Rect2 = get_parent().arena_bounds
	global_position = global_position.clamp(bounds.position, bounds.end)

	if damage_area and damage_area.overlaps_body(player):
		if contact_damage_cooldown <= 0.0 and player.take_damage(attack_damage):
			contact_damage_cooldown = contact_damage_interval

	if health_bar:
		health_bar.value = hp

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	if health_bar:
		health_bar.value = hp
	if hp <= 0:
		queue_free()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.3))
	draw_circle(Vector2.ZERO, 16, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	if attack_pending:
		draw_rect(_attack_rect(), Color(1, 0.65, 0.1, 0.35))
		draw_rect(_attack_rect(), Color(1, 0.7, 0.2, 1), false, 2)
	elif recovery_timer > 0.0:
		draw_rect(_attack_rect(), Color(1, 0.2, 0.1, 0.3))

func _attack_rect() -> Rect2:
	var reach := 140.0 if is_boss else 90.0
	return Rect2(Vector2(0 if attack_direction > 0 else -reach, -22), Vector2(reach, 44))

func _release_attack() -> void:
	attack_pending = false
	recovery_timer = 0.55 if is_boss else 0.4
	attack_cooldown_timer = 1.8 if is_boss else 2.2
	if _attack_rect().grow(6).has_point(player.global_position - global_position):
		player.take_damage(attack_damage)
