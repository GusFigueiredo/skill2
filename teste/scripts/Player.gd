extends CharacterBody2D

@export var speed: float = 220.0
@export var jump_velocity: float = -420.0
@export var gravity: float = 980.0
@export var max_hp: int = 10
@export var attack_damage: int = 1
@export var dodge_distance: float = 120.0
@export var dodge_duration: float = 0.22
@export var dodge_cooldown: float = 0.8
@export var attack_cooldown: float = 1.0
@export var damage_interval: float = 0.7

var has_moved: bool = false
var has_attacked: bool = false
var has_dodged: bool = false
var hp: int
var can_dodge: bool = true
var is_dodging: bool = false
var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var dodge_direction: int = 1
var facing: int = 1
var attack_cooldown_timer: float = 0.0
var damage_cooldown: float = 0.0
var dodge_collision_exceptions: Array[PhysicsBody2D] = []
var dodge_key_was_pressed: bool = false
var jump_key_was_pressed: bool = false
var attack_flash_timer: float = 0.0
var jump_height: float = 0.0
var jump_speed: float = 0.0
var sprite_base_position: Vector2
var dodge_vector := Vector2.RIGHT
var is_falling: bool = false
var fall_timer: float = 0.0
var last_safe_position: Vector2
var sound_effects := preload("res://scripts/SoundEffects.gd").new()

@onready var attack_area: Area2D = $AttackArea
@onready var sprite: ColorRect = $Sprite

func _ready() -> void:
    add_child(sound_effects)
    sound_effects.setup({
        "attack": "res://soundeffect/Personagem/ataque.wav",
        "damage": "res://soundeffect/Personagem/dano tomado.wav",
        "dodge": "res://soundeffect/Personagem/dodge.wav",
        "jump": "res://soundeffect/Personagem/Pulo.wav",
    })
    hp = max_hp
    last_safe_position = position
    motion_mode = MOTION_MODE_FLOATING
    sprite_base_position = sprite.position
    sprite.pivot_offset = sprite.size * 0.5
    add_to_group("player")
    collision_layer = 2
    collision_mask = 1 | 4
    attack_area.position.x = 28
    attack_area.monitoring = true
    attack_area.monitorable = false
    attack_area.collision_layer = 0
    attack_area.collision_mask = 4

func _physics_process(delta: float) -> void:
    if is_falling:
        fall_timer -= delta
        sprite.scale = Vector2.ONE * maxf(0.05, fall_timer / 0.45)
        sprite.modulate.a = maxf(0.0, fall_timer / 0.45)
        if fall_timer <= 0.0:
            _finish_fall()
        return
    attack_flash_timer = maxf(0.0, attack_flash_timer - delta)
    queue_redraw()
    var jump_pressed := Input.is_key_pressed(KEY_SPACE)
    if jump_pressed and not jump_key_was_pressed and jump_height <= 0.0:
        jump_speed = -jump_velocity
        sound_effects.play_effect("jump")
    jump_key_was_pressed = jump_pressed
    if jump_height > 0.0 or jump_speed > 0.0:
        jump_speed -= gravity * delta
        jump_height = maxf(0.0, jump_height + jump_speed * delta)
        if jump_height <= 0.0:
            jump_speed = 0.0
    sprite.position = sprite_base_position - Vector2(0, jump_height)
    var dodge_key_pressed := Input.is_key_pressed(KEY_SHIFT)
    var dodge_just_pressed := dodge_key_pressed and not dodge_key_was_pressed
    dodge_key_was_pressed = dodge_key_pressed
    if not can_dodge:
        dodge_cooldown_timer = max(0.0, dodge_cooldown_timer - delta)
        can_dodge = dodge_cooldown_timer <= 0.0

    if attack_cooldown_timer > 0.0:
        attack_cooldown_timer = max(0.0, attack_cooldown_timer - delta)

    if damage_cooldown > 0.0:
        damage_cooldown = max(0.0, damage_cooldown - delta)

    if is_dodging:
        _update_dodge(delta)
        return

    var move_input := 0.0
    if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
        move_input -= 1.0
    if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
        move_input += 1.0

    if move_input != 0.0:
        facing = 1 if move_input > 0 else -1
        sprite.scale.x = facing
        attack_area.position.x = 32 * facing

    var depth_input := Input.get_axis("ui_up", "ui_down")
    if Input.is_key_pressed(KEY_W):
        depth_input -= 1.0
    if Input.is_key_pressed(KEY_S):
        depth_input += 1.0
    var movement := Vector2(move_input, depth_input).limit_length()
    velocity = movement * speed
    if movement.length_squared() > 0.0:
        has_moved = true

    if Input.is_key_pressed(KEY_K) and attack_cooldown_timer <= 0.0:
        _attack()

    if dodge_just_pressed and can_dodge:
        _start_dodge(move_input)
        dodge_vector = movement.normalized() if movement.length_squared() > 0.0 else Vector2(facing, 0)
        _update_dodge(delta)
        return

    var previous_position := position
    move_and_slide()
    _clamp_to_arena()
    get_parent().check_player_floor(previous_position)


func _attack() -> void:
    if attack_cooldown_timer > 0.0 or is_dodging or hp <= 0:
        return

    attack_cooldown_timer = attack_cooldown
    sound_effects.play_effect("attack")
    attack_flash_timer = 0.12
    has_attacked = true
    attack_area.position.x = 45 * facing
    var attack_shape := attack_area.get_child(0) as CollisionShape2D
    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = attack_shape.shape
    query.transform = attack_shape.global_transform
    query.collision_mask = 4
    for hit in get_world_2d().direct_space_state.intersect_shape(query):
        var body = hit.collider
        if body.has_method("take_damage"):
            body.take_damage(attack_damage)

func _start_dodge(move_input: float) -> void:
    if not can_dodge or is_dodging or hp <= 0:
        return
    is_dodging = true
    sound_effects.play_effect("dodge")
    has_dodged = true
    can_dodge = false
    dodge_timer = dodge_duration
    dodge_cooldown_timer = dodge_cooldown
    dodge_direction = 1 if move_input >= 0.0 else -1
    if move_input == 0.0:
        dodge_direction = facing

    dodge_vector = Vector2(dodge_direction, 0)

    # Ignore only solid enemy bodies; keep ground collisions and damage detection active.
    for enemy in get_tree().get_nodes_in_group("enemy"):
        if enemy is PhysicsBody2D:
            add_collision_exception_with(enemy)
            enemy.add_collision_exception_with(self)
            dodge_collision_exceptions.append(enemy)

func _update_dodge(delta: float) -> void:
    var step := minf(delta, dodge_timer)
    velocity = dodge_vector * dodge_distance / maxf(dodge_duration, 0.001) * step / delta
    var previous_position := position
    move_and_slide()
    _clamp_to_arena()
    get_parent().check_player_floor(previous_position)
    if is_falling:
        return
    dodge_timer = maxf(0.0, dodge_timer - delta)
    sprite.rotation = dodge_direction * TAU * (1.0 - dodge_timer / maxf(dodge_duration, 0.001))
    if dodge_timer <= 0.0:
        _end_dodge()

func _end_dodge() -> void:
    is_dodging = false
    velocity = Vector2.ZERO
    sprite.rotation = 0.0
    for enemy in dodge_collision_exceptions:
        if is_instance_valid(enemy):
            remove_collision_exception_with(enemy)
            enemy.remove_collision_exception_with(self)
    dodge_collision_exceptions.clear()

func take_damage(amount: int) -> bool:
    if hp <= 0 or is_falling or is_dodging or damage_cooldown > 0.0:
        return false
    damage_cooldown = damage_interval
    hp = max(0, hp - amount)
    if amount > 0:
        sound_effects.play_effect("damage")
    if hp <= 0:
        hp = 0
        var game_manager = get_tree().get_first_node_in_group("game_manager")
        if game_manager and game_manager.has_method("trigger_death"):
            game_manager.trigger_death()
        set_physics_process(false)
        visible = false
    return true

func _clamp_to_arena() -> void:
    var bounds: Rect2 = get_parent().arena_bounds
    global_position = global_position.clamp(bounds.position, bounds.end)

func _draw() -> void:
    draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.3))
    draw_circle(Vector2.ZERO, 16, Color(0, 0, 0, 0.35))
    draw_set_transform(Vector2.ZERO)
    if attack_flash_timer > 0.0:
        var origin := Vector2(45 * facing - 24, -14)
        draw_rect(Rect2(origin, Vector2(48, 28)), Color(1, 0.85, 0.3, 0.65))

func fall_into_pit() -> void:
    if is_falling or hp <= 0:
        return
    _end_dodge()
    is_falling = true
    hp = 0
    get_parent().trigger_death()
    fall_timer = 0.45
    jump_height = 0.0
    jump_speed = 0.0
    sprite.position = sprite_base_position
    collision_layer = 0
    collision_mask = 0

func _finish_fall() -> void:
    set_physics_process(false)
    visible = false
