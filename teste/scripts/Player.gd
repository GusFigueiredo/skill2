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
var has_jumped: bool = false
var hp: int
var can_dodge: bool = true
var is_dodging: bool = false
var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var dodge_direction: int = 1
var facing: int = 1
var attack_vertical: int = 0
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
var combat_bounds := Rect2()
var attack_reach: float = 90.0
var dodge_protected_frame: int = -1
var dodge_vfx_timer: float = 0.0
var dodge_rewarded := false
var seduction_source: Node2D
var seduction_input := 0
var control_locked := false

@onready var attack_area: Area2D = $AttackArea
@onready var sprite: AnimatedSprite2D = $Sprite

func _ready() -> void:
    add_child(sound_effects)
    sound_effects.setup({
        "attack": "res://soundeffect/Personagem/ataque.wav",
        "damage": "res://soundeffect/Personagem/dano tomado.wav",
        "dodge": "res://soundeffect/Personagem/dodge.wav",
        "jump": "res://soundeffect/Personagem/Pulo.wav",
    }, {"attack": 12.8, "dodge": 7.0})
    hp = max_hp
    combat_bounds = preload("res://scripts/CombatGeometry.gd").setup(self, false)
    attack_reach = maxf(90.0, combat_bounds.size.y * 1.2)
    var strike := RectangleShape2D.new()
    strike.size = Vector2(attack_reach, combat_bounds.size.y * 0.55)
    (attack_area.get_child(0) as CollisionShape2D).shape = strike
    attack_area.position.y = combat_bounds.get_center().y
    last_safe_position = position
    motion_mode = MOTION_MODE_FLOATING
    sprite_base_position = sprite.position
    add_to_group("player")
    collision_layer = 2
    collision_mask = 1 | 4
    attack_area.position.x = attack_reach * 0.5
    attack_area.monitoring = true
    attack_area.monitorable = false
    attack_area.collision_layer = 0
    attack_area.collision_mask = 4

func _physics_process(delta: float) -> void:
    if control_locked:
        return
    if is_falling:
        fall_timer -= delta
        sprite.scale = Vector2.ONE * 0.9375 * maxf(0.05, fall_timer / 0.45)
        sprite.modulate.a = maxf(0.0, fall_timer / 0.45)
        if fall_timer <= 0.0:
            _finish_fall()
        return
    attack_flash_timer = maxf(0.0, attack_flash_timer - delta)
    queue_redraw()
    var jump_pressed := Input.is_key_pressed(KEY_SPACE)
    if jump_pressed and not jump_key_was_pressed and jump_height <= 0.0 and not is_instance_valid(seduction_source):
        jump_speed = -jump_velocity
        has_jumped = true
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

    if is_instance_valid(seduction_source):
        _update_seduction(delta)
        return

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
        sprite.flip_h = facing < 0

    var depth_input := Input.get_axis("ui_up", "ui_down")
    if Input.is_key_pressed(KEY_W):
        depth_input -= 1.0
    if Input.is_key_pressed(KEY_S):
        depth_input += 1.0
    _update_attack_direction(Vector2(move_input, depth_input))
    var movement := Vector2(move_input, depth_input).limit_length()
    velocity = movement * speed
    if movement.length_squared() > 0.0:
        has_moved = true

    if Input.is_key_pressed(KEY_K) and attack_cooldown_timer <= 0.0:
        _attack()

    if dodge_just_pressed and can_dodge and not _is_airborne():
        _start_dodge(move_input)
        dodge_vector = movement.normalized() if movement.length_squared() > 0.0 else Vector2(facing, 0)
        _update_dodge(delta)
        return

    var previous_position := position
    move_and_slide()
    _clamp_to_arena()
    get_parent().check_player_floor(previous_position)

func _input(event: InputEvent) -> void:
    if control_locked or is_instance_valid(seduction_source):
        return
    if get_parent().get("finished") or get_parent().get("boss_intro_running"):
        return
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode != KEY_SHIFT and event.physical_keycode != KEY_SHIFT:
        return
    if get_tree().paused or is_falling or hp <= 0 or not can_dodge or is_dodging or _is_airborne():
        return
    var movement := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    movement += Vector2(float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)), float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)))
    _start_dodge(movement.x)
    dodge_vector = movement.normalized() if movement.length_squared() > 0.0 else Vector2(facing, 0)
    dodge_key_was_pressed = true

func _update_attack_direction(movement: Vector2) -> void:
    if movement.y != 0.0:
        attack_vertical = 1 if movement.y > 0.0 else -1
    elif movement.x != 0.0:
        attack_vertical = 0
    _orient_attack_area()

func _attack_heading() -> Vector2:
    return Vector2(0, attack_vertical) if attack_vertical != 0 else Vector2(facing, 0)

func _orient_attack_area() -> void:
    var heading := _attack_heading()
    attack_area.position = Vector2(0, combat_bounds.get_center().y) + heading * attack_reach * 0.5
    attack_area.rotation = heading.angle()

func _attack() -> void:
    if control_locked or attack_cooldown_timer > 0.0 or is_dodging or hp <= 0 or is_instance_valid(seduction_source) or get_parent().get("finished") or get_parent().get("boss_intro_running"):
        return

    attack_cooldown_timer = attack_cooldown
    # Damage is immediate: show the extended punch on that same physics tick.
    sprite.play("attack")
    sprite.set_frame_and_progress(1, 0.0)
    sound_effects.play_effect("attack")
    attack_flash_timer = 0.12
    preload("res://scripts/CombatVFX.gd").spawn(self, "slash", global_position + Vector2(0, combat_bounds.get_center().y - jump_height), _attack_heading(), Color("ffe5a0"), attack_reach * 0.85)
    has_attacked = true
    _orient_attack_area()
    var attack_shape := attack_area.get_child(0) as CollisionShape2D
    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = attack_shape.shape
    query.transform = attack_shape.global_transform
    query.collision_mask = 8
    query.collide_with_areas = true
    query.collide_with_bodies = false
    var damaged: Array[Node] = []
    for hit in get_world_2d().direct_space_state.intersect_shape(query):
        var body = hit.collider.get_parent()
        if body.has_method("take_damage") and body not in damaged:
            damaged.append(body)
            body.take_damage(attack_damage)

func _is_airborne() -> bool:
    return jump_height > 0.0 or jump_speed > 0.0

func _start_dodge(move_input: float) -> void:
    if control_locked or not can_dodge or is_dodging or hp <= 0 or is_instance_valid(seduction_source) or _is_airborne() or get_parent().get("finished") or get_parent().get("boss_intro_running"):
        return
    is_dodging = true
    dodge_rewarded = false
    dodge_vfx_timer = 0.0
    preload("res://scripts/CombatVFX.gd").spawn(self, "smoke", global_position, Vector2.RIGHT, Color("b8d5ce"), 38.0)
    sprite.play("dodge")
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
    dodge_vfx_timer -= delta
    if dodge_vfx_timer <= 0.0:
        preload("res://scripts/CombatVFX.gd").afterimage(self)
        preload("res://scripts/CombatVFX.gd").spawn(self, "dash", global_position, dodge_vector, Color(0.65, 0.88, 0.83, 0.3), 26.0)
        dodge_vfx_timer = 0.045
    var step := minf(delta, dodge_timer)
    velocity = dodge_vector * dodge_distance / maxf(dodge_duration, 0.001) * step / delta
    var previous_position := position
    move_and_slide()
    _clamp_to_arena()
    get_parent().check_player_floor(previous_position)
    if is_falling:
        return
    dodge_timer = maxf(0.0, dodge_timer - delta)
    # The dodge animation provides the rolling poses.
    if dodge_timer <= 0.0:
        _end_dodge(true)

func _end_dodge(protect_current_frame: bool = false) -> void:
    if protect_current_frame:
        dodge_protected_frame = Engine.get_physics_frames()
    is_dodging = false
    if sprite.animation == "dodge":
        sprite.play("idle")
    velocity = Vector2.ZERO
    sprite.rotation = 0.0
    for enemy in dodge_collision_exceptions:
        if is_instance_valid(enemy):
            remove_collision_exception_with(enemy)
            enemy.remove_collision_exception_with(self)
    dodge_collision_exceptions.clear()

func take_damage(amount: int) -> bool:
    if hp <= 0 or is_falling or amount <= 0:
        return false
    if is_dodge_invulnerable():
        if not dodge_rewarded:
            dodge_rewarded = true
            var feedback = get_parent().get_node_or_null("CombatFeedback")
            if feedback != null:
                feedback.evaded(self)
        return false
    if damage_cooldown > 0.0:
        return false
    damage_cooldown = damage_interval
    hp = max(0, hp - amount)
    if amount > 0:
        preload("res://scripts/DamageImpact.gd").spawn(self, amount)
        sound_effects.play_effect("damage")
    if hp <= 0:
        hp = 0
        var game_manager = get_tree().get_first_node_in_group("game_manager")
        if game_manager and game_manager.has_method("trigger_death"):
            game_manager.trigger_death()
        set_physics_process(false)
        collision_layer = 0
        collision_mask = 0
        sprite.play("death")
    return true

func is_dodge_invulnerable() -> bool:
    return is_dodging or dodge_protected_frame == Engine.get_physics_frames()

func _clamp_to_arena() -> void:
    var bounds: Rect2 = get_parent().arena_bounds
    global_position = global_position.clamp(bounds.position, bounds.end)

func begin_seduction(source: Node2D) -> void:
    _end_dodge()
    seduction_source = source
    seduction_input = 0
    jump_height = 0.0
    jump_speed = 0.0
    sprite.position = sprite_base_position
    attack_vertical = 0

func end_seduction() -> void:
    seduction_source = null
    seduction_input = 0
    velocity = Vector2.ZERO

func _update_seduction(delta: float) -> void:
    var left := Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A)
    var right := Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)
    var direction := int(right) - int(left)
    if direction != 0 and direction != seduction_input:
        get_parent().register_resistance(direction)
    seduction_input = direction
    if not is_instance_valid(seduction_source):
        return
    var pull: Vector2 = (seduction_source.global_position - global_position).normalized()
    facing = 1 if pull.x >= 0.0 else -1
    velocity = Vector2(direction * speed * 0.2, 0) + pull * get_parent().seduction_pull_speed()
    var previous_position := position
    move_and_slide()
    _clamp_to_arena()
    get_parent().check_player_floor(previous_position)

func _draw() -> void:
    draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.3))
    draw_circle(Vector2.ZERO, 16, Color(0, 0, 0, 0.35))
    draw_set_transform(Vector2.ZERO)

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
