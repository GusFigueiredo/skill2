extends CharacterBody2D

@export var speed: float = 220.0
@export var jump_velocity: float = -420.0
@export var gravity: float = 980.0
@export var max_hp: int = 10
@export var attack_damage: int = 1
@export var dodge_distance: float = 120.0
@export var dodge_duration: float = 0.22
@export var dodge_cooldown: float = 0.8
@export var dodge_invulnerable_time: float = 0.3
@export var attack_cooldown: float = 1.5

var hp: int
var can_dodge: bool = true
var is_dodging: bool = false
var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var dodge_direction: int = 1
var facing: int = 1
var attack_cooldown_timer: float = 0.0
var damage_cooldown: float = 0.0

@onready var attack_area: Area2D = $AttackArea
@onready var sprite: ColorRect = $Sprite

func _ready() -> void:
    hp = max_hp
    add_to_group("player")
    collision_layer = 2
    collision_mask = 1 | 4
    attack_area.position.x = 28
    attack_area.monitoring = true
    attack_area.monitorable = false
    attack_area.collision_layer = 0
    attack_area.collision_mask = 4

func _physics_process(delta: float) -> void:
    if attack_cooldown_timer > 0.0:
        attack_cooldown_timer = max(0.0, attack_cooldown_timer - delta)

    if damage_cooldown > 0.0:
        damage_cooldown = max(0.0, damage_cooldown - delta)

    if is_dodging:
        dodge_timer -= delta
        velocity.x = dodge_direction * (dodge_distance / dodge_duration)
        if dodge_timer <= 0.0:
            _end_dodge()
        move_and_slide()
        return

    var move_input := 0.0
    if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
        move_input -= 1.0
    if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
        move_input += 1.0

    if move_input != 0.0:
        facing = 1 if move_input > 0 else -1
        sprite.scale.x = facing

    velocity.x = move_input * speed

    if (Input.is_action_just_pressed("ui_up") or Input.is_key_pressed(KEY_W)) and is_on_floor():
        velocity.y = jump_velocity

    if Input.is_key_pressed(KEY_K) and attack_cooldown_timer <= 0.0:
        _attack()

    if Input.is_key_pressed(KEY_SHIFT) and can_dodge:
        _start_dodge(move_input)

    if not is_on_floor():
        velocity.y += gravity * delta

    move_and_slide()

    if not can_dodge:
        dodge_cooldown_timer -= delta
        if dodge_cooldown_timer <= 0.0:
            can_dodge = true

func _attack() -> void:
    if attack_cooldown_timer > 0.0:
        return

    attack_cooldown_timer = attack_cooldown
    attack_area.position.x = 32 * facing
    var bodies = attack_area.get_overlapping_bodies()
    for body in bodies:
        if body.has_method("take_damage"):
            body.take_damage(attack_damage)

func _start_dodge(move_input: float) -> void:
    is_dodging = true
    can_dodge = false
    dodge_timer = dodge_duration
    dodge_cooldown_timer = dodge_cooldown
    dodge_direction = 1 if move_input >= 0.0 else -1
    if move_input == 0.0:
        dodge_direction = facing

    collision_mask = 1
    for enemy in get_tree().get_nodes_in_group("enemy"):
        if enemy.has_method("set_collision_mask_value"):
            enemy.set_collision_mask_value(2, false)
    attack_area.monitoring = false

func _end_dodge() -> void:
    is_dodging = false
    velocity.x = 0.0
    collision_mask = 1 | 4
    for enemy in get_tree().get_nodes_in_group("enemy"):
        if enemy.has_method("set_collision_mask_value"):
            enemy.set_collision_mask_value(2, true)
    attack_area.monitoring = true

func take_damage(amount: int) -> void:
    if is_dodging:
        return
    if damage_cooldown > 0.0:
        return
    damage_cooldown = 0.5
    hp = max(0, hp - amount)
    if hp <= 0:
        hp = 0
        var game_manager = get_tree().get_first_node_in_group("game_manager")
        if game_manager and game_manager.has_method("trigger_death"):
            game_manager.trigger_death()
        set_physics_process(false)
        visible = false
