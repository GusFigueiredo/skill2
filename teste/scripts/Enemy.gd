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
var combat_bounds := Rect2()
var contact_requires_separation: bool = false

@onready var health_bar: ProgressBar = $HealthBar
@onready var damage_area: Area2D = $DamageArea

func _ready() -> void:
	hp = max_hp
	combat_bounds = preload("res://scripts/CombatGeometry.gd").setup(self, true)
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
		health_bar.visible = not is_boss
		health_bar.max_value = max_hp
		health_bar.value = hp
		var visual := $Sprite as AnimatedSprite2D
		var top := combat_bounds.position.y
		for animation_name in visual.sprite_frames.get_animation_names():
			for index in visual.sprite_frames.get_frame_count(animation_name):
				var image := visual.sprite_frames.get_frame_texture(animation_name, index).get_image()
				top = minf(top, visual.position.y + (image.get_used_rect().position.y - image.get_height() * 0.5) * visual.scale.y)
		var bar_size := Vector2(180, 60) if is_boss else Vector2(100, 18)
		health_bar.position = Vector2(-bar_size.x * 0.5, top - bar_size.y - 8)
		health_bar.size = bar_size
		health_bar.z_index = 5
		health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

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
		attack_timer = 0.67 if is_boss else 0.65
		attack_direction = direction
		velocity = Vector2.ZERO
	move_and_slide()
	var bounds: Rect2 = get_parent().arena_bounds
	global_position = global_position.clamp(bounds.position, bounds.end)

	_update_contact_damage()

	if health_bar:
		health_bar.value = hp

func _update_contact_damage() -> void:
	if not damage_area or not damage_area.monitoring or not is_instance_valid(player):
		return
	# Area overlap lists can lag behind movement by a physics frame.
	var contact_shape := damage_area.get_child(0) as CollisionShape2D
	var player_shape := player.get_node("CollisionShape2D") as CollisionShape2D
	var contact_rect: Rect2 = contact_shape.global_transform * Rect2(-contact_shape.shape.size * 0.5, contact_shape.shape.size)
	var player_rect: Rect2 = player_shape.global_transform * Rect2(-player_shape.shape.size * 0.5, player_shape.shape.size)
	if not contact_rect.intersects(player_rect):
		contact_requires_separation = false
		return
	if player.is_dodge_invulnerable():
		contact_requires_separation = true
		return
	# A roll may finish inside a large enemy. That contact stays harmless until
	# separation; a later contact is a new hit. Attacks still use take_damage.
	if contact_requires_separation:
		return
	if contact_damage_cooldown <= 0.0 and player.take_damage(attack_damage):
		contact_damage_cooldown = contact_damage_interval

func take_damage(amount: int) -> void:
	if hp <= 0 or amount <= 0:
		return
	hp = max(0, hp - amount)
	preload("res://scripts/DamageImpact.gd").spawn(self, amount)
	if health_bar:
		health_bar.value = hp
	if hp <= 0:
		_show_defeat()
		queue_free()

func _show_defeat() -> void:
	# A detached visual lets the wave advance immediately while the fall plays.
	var visual := $Sprite as AnimatedSprite2D
	var remains := AnimatedSprite2D.new()
	remains.sprite_frames = visual.sprite_frames
	remains.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	remains.scale = visual.scale
	remains.flip_h = visual.flip_h
	get_parent().add_child(remains)
	remains.global_position = visual.global_position
	remains.play("death" if remains.sprite_frames.has_animation("death") else "idle")
	var fade := remains.create_tween()
	fade.tween_interval(0.6)
	fade.tween_property(remains, "modulate:a", 0.0, 0.3)
	fade.tween_callback(remains.queue_free)

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.3))
	draw_circle(Vector2.ZERO, 16, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	if attack_pending:
		preload("res://scripts/CombatVFX.gd").warning(self, _attack_rect(), clampf(1.0 - attack_timer / 0.65, 0.0, 1.0), Color("ffc05c"))
	elif recovery_timer > 0.0:
		draw_rect(_attack_rect(), Color(1, 0.2, 0.1, 0.3))

func _attack_rect() -> Rect2:
	var reach := maxf(175.0 if is_boss else 90.0, combat_bounds.size.x * 1.4)
	var width := maxf(55.0 if is_boss else 44.0, ($CollisionShape2D.shape as RectangleShape2D).size.y * 2.0)
	return Rect2(Vector2(0 if attack_direction > 0 else -reach, -width / 2.0), Vector2(reach, width))

func _release_attack() -> void:
	preload("res://scripts/CombatVFX.gd").spawn(self, "slash", global_position + Vector2(0, combat_bounds.get_center().y), Vector2(attack_direction, 0), Color("ff9565"), _attack_rect().size.x * 0.8)
	attack_pending = false
	recovery_timer = 0.55 if is_boss else 0.4
	attack_cooldown_timer = 1.20 if is_boss else 2.2
	var player_size: Vector2 = player.get_node("CollisionShape2D").shape.size
	var player_rect := Rect2(player.global_position - global_position - player_size * 0.5, player_size)
	if _attack_rect().intersects(player_rect):
		player.take_damage(attack_damage)
