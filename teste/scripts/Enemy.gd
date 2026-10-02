extends CharacterBody2D

@export var max_hp: int = 3
@export var speed: float = 70.0
@export var attack_damage: int = 1
@export var is_boss: bool = false
@export var contact_damage_interval: float = 0.7

var hp: int
var player: CharacterBody2D
var direction: int = -1
var contact_damage_cooldown: float = 0.0

@onready var health_bar: ProgressBar = $HealthBar
@onready var damage_area: Area2D = $DamageArea

func _ready() -> void:
	hp = max_hp
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
			damage_shape.shape.size += Vector2(8, 8)
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

	if player.global_position.x < global_position.x:
		direction = -1
	else:
		direction = 1

	if abs(player.global_position.x - global_position.x) < 180.0:
		velocity.x = direction * speed
	else:
		velocity.x = 0.0

	if not is_on_floor():
		velocity.y += 980.0 * delta

	move_and_slide()

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
