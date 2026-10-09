extends "res://scripts/Level1.gd"

enum State { IDLE, PREPARING, CASTING, SEDUCING, FALLING, MINIONS, VULNERABLE, DROWNING, DEFEATED }

const PREPARATION_SECONDS := 2.5
const INTRO_IDLE_SECONDS := 1.25
const CAST_SECONDS := 0.55
const TRANSE_SECONDS := 7.0
const FALL_SECONDS := 0.75
const ATTACK_WINDOW_SECONDS := 2.0
const DROWNING_SECONDS := 3.0
const CORPSE_SINK_SECONDS := 1.8
const RESISTANCE_COOLDOWN := 0.2
const RESISTANCE_REQUIRED := 8
const WATER_EDGE := 620.0
const WATER_POSITION := Vector2(780, 450)
const SHORE_POSITION := Vector2(570, 450)
const MINION_SCENE := preload("res://scenes/Enemy.tscn")

var state: State = State.IDLE
var state_timer := INTRO_IDLE_SECONDS
var preparation_duration := PREPARATION_SECONDS
var resistance := 0.0
var last_resistance_direction := 0
var resistance_idle := 0.0
var resistance_cooldown := 0.0
var water_exposure := 0.0
var trance_enemy: CharacterBody2D
var minions: Array[CharacterBody2D] = []
var cycle_count := 0
var fight_elapsed := 0.0
var resistance_bar: ProgressBar
var veil: ColorRect
var river_effects: Node2D
var audio_bus_name := ""
var low_pass: AudioEffectLowPassFilter
var original_music_volume := -10.0
var drowning_start_position := Vector2.ZERO
var drowning_start_depth := 0.0
var water_surface := Vector2.ZERO
var submersion_material: ShaderMaterial
var normal_player_material: Material
var corpse_elapsed := -1.0
var corpse_start_offset := Vector2.ZERO
var corpse_start_color := Color.WHITE
var key_prompt: Control
var camera_tween: Tween
var camera_is_focused := false
var normal_camera_zoom := Vector2.ONE
var normal_camera_position := Vector2.ZERO
var normal_camera_smoothing := true

func _setup_encounters() -> void:
    pits = []
    arena_bounds = Rect2(55, 345, 1025, 210)
    waves = [[boss]]
    boss.position = WATER_POSITION
    player.position = Vector2(440, 460)

func _ready() -> void:
    super._ready()
    # Match the supplied composition: dry bank on the left, water on the right.
    $Ground.position = Vector2(0, 200)
    $Ground.scale.y = 0.6
    $Ground.region_rect.position = Vector2.ZERO
    $Ground.region_rect.size.x = $Ground.texture.get_width()
    $Background.position.y = -80.0
    $Background.region_rect.position.y = 0.0
    var camera := player.get_node("Camera2D") as Camera2D
    normal_camera_zoom = camera.zoom
    normal_camera_position = camera.position
    normal_camera_smoothing = camera.position_smoothing_enabled
    # Keep the inherited 1.8 zoom, actor scales and player-following camera.
    camera.limit_right = ceili(arena_bounds.end.x + 70)
    camera.reset_smoothing()
    $HUD/BossHealth/BossName.text = "IARA"
    _build_fight_feedback()
    _setup_river_audio()
    _update_hud()

func _build_fight_feedback() -> void:
    resistance_bar = ProgressBar.new()
    resistance_bar.name = "IaraResistance"
    resistance_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    resistance_bar.offset_left = -110
    resistance_bar.offset_top = 100
    resistance_bar.offset_right = 110
    resistance_bar.offset_bottom = 112
    resistance_bar.custom_minimum_size = Vector2(0, 12)
    resistance_bar.max_value = RESISTANCE_REQUIRED
    resistance_bar.show_percentage = false
    $HUD.add_child(resistance_bar)
    var overlay := CanvasLayer.new()
    overlay.layer = 1
    add_child(overlay)
    veil = ColorRect.new()
    veil.color = Color(0.015, 0.045, 0.12, 0)
    veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
    overlay.add_child(veil)
    veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    river_effects = preload("res://scripts/IaraSpellEffects.gd").new()
    river_effects.fight = self
    add_child(river_effects)
    key_prompt = preload("res://scripts/TranceKeyPrompt.gd").new()
    key_prompt.fight = self
    key_prompt.player = player
    $HUD.add_child(key_prompt)

func _setup_river_audio() -> void:
    original_music_volume = music.volume_db
    audio_bus_name = "IaraRiver%d" % get_instance_id()
    AudioServer.add_bus()
    var index := AudioServer.bus_count - 1
    AudioServer.set_bus_name(index, audio_bus_name)
    low_pass = AudioEffectLowPassFilter.new()
    low_pass.cutoff_hz = 20000.0
    AudioServer.add_bus_effect(index, low_pass)
    music.bus = audio_bus_name

func _exit_tree() -> void:
    if audio_bus_name != "":
        var index := AudioServer.get_bus_index(audio_bus_name)
        if index >= 0:
            AudioServer.remove_bus(index)

func _process(delta: float) -> void:
    _update_hud()
    if corpse_elapsed >= 0.0:
        _update_sinking_corpse(delta)
    if submersion_material != null and player.sprite.material == submersion_material:
        submersion_material.set_shader_parameter("phase", river_effects.clock)
    if camera_is_focused and state == State.SEDUCING and player.hp > 0:
        var camera := player.get_node("Camera2D") as Camera2D
        var target: Vector2 = player.global_position + player.combat_bounds.get_center()
        camera.global_position = camera.global_position.lerp(target, 1.0 - exp(-delta * 12.0))

func _physics_process(delta: float) -> void:
    if finished or player.hp <= 0:
        return
    fight_elapsed += delta
    resistance_cooldown = maxf(0.0, resistance_cooldown - delta)
    state_timer = maxf(0.0, state_timer - delta)
    match state:
        State.IDLE:
            if state_timer <= 0.0:
                _start_cycle()
        State.PREPARING:
            boss.position = boss.position.move_toward(WATER_POSITION, 260.0 * delta)
            if state_timer <= 0.0:
                state = State.CASTING
                state_timer = CAST_SECONDS
        State.CASTING:
            if state_timer <= 0.0:
                _begin_seduction()
        State.SEDUCING:
            resistance_idle += delta
            if resistance_idle > 1.25:
                resistance = maxf(0.0, resistance - delta * 1.6)
            if state_timer <= 0.0:
                _begin_drowning()
        State.FALLING:
            boss.position = boss.position.move_toward(SHORE_POSITION, 350.0 * delta)
            if state_timer <= 0.0:
                boss.position = SHORE_POSITION
                _spawn_minions()
        State.MINIONS:
            var any_alive := false
            for minion in minions:
                if is_instance_valid(minion) and minion.hp > 0:
                    any_alive = true
            if not any_alive:
                state = State.VULNERABLE
                state_timer = ATTACK_WINDOW_SECONDS
                preload("res://scripts/CombatVFX.gd").spawn(boss, "ring", boss.position, Vector2.RIGHT, Color("b7fff0"), 60)
        State.VULNERABLE:
            if state_timer <= 0.0:
                _start_cycle()
        State.DROWNING:
            _update_drowning()
    if state != State.DROWNING:
        _update_water(delta)

func _start_cycle() -> void:
    state = State.PREPARING
    state_timer = PREPARATION_SECONDS if boss.hp > boss.max_hp / 2 else 2.0
    preparation_duration = state_timer
    resistance = 0.0
    last_resistance_direction = 0
    water_exposure = 0.0
    _clear_seduction()

func _begin_seduction() -> void:
    state = State.SEDUCING
    state_timer = TRANSE_SECONDS
    resistance = 0.0
    last_resistance_direction = 0
    resistance_idle = 0.0
    resistance_cooldown = 0.0
    player.begin_seduction(boss)
    key_prompt._process(0.0)
    _focus_on_player()
    _spawn_trance_enemy()
    veil.color.a = 0.36
    music.volume_db = original_music_volume - 8.0
    music.pitch_scale = 0.85
    low_pass.cutoff_hz = 850.0

func register_resistance(direction: int) -> void:
    if state != State.SEDUCING or resistance_cooldown > 0.0001 or direction == 0 or direction == last_resistance_direction:
        return
    last_resistance_direction = direction
    resistance_idle = 0.0
    resistance_cooldown = RESISTANCE_COOLDOWN
    resistance += 1.0
    key_prompt.flash_press(direction)
    if resistance >= RESISTANCE_REQUIRED:
        state = State.FALLING
        state_timer = FALL_SECONDS
        water_exposure = 0.0
        _clear_seduction()
        boss.get_node("Sprite").play("fall")

func seduction_pull_speed() -> float:
    return 58.0 + (TRANSE_SECONDS - state_timer) * 4.0

func _clear_seduction() -> void:
    player.end_seduction()
    if key_prompt != null:
        key_prompt.hide()
    _restore_camera()
    if veil != null:
        veil.color.a = 0.0
    music.pitch_scale = 1.0
    music.volume_db = original_music_volume
    if low_pass != null:
        low_pass.cutoff_hz = 20000.0

func _focus_on_player() -> void:
    var camera := player.get_node("Camera2D") as Camera2D
    var center := camera.get_screen_center_position()
    if camera_tween != null and camera_tween.is_valid():
        camera_tween.kill()
    camera_is_focused = true
    camera.top_level = true
    camera.position_smoothing_enabled = false
    camera.global_position = center
    camera_tween = create_tween()
    camera_tween.tween_property(camera, "zoom", normal_camera_zoom * 1.35, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _restore_camera() -> void:
    if not camera_is_focused:
        return
    camera_is_focused = false
    var camera := player.get_node("Camera2D") as Camera2D
    if camera_tween != null and camera_tween.is_valid():
        camera_tween.kill()
    camera_tween = create_tween().set_parallel(true)
    camera_tween.tween_property(camera, "zoom", normal_camera_zoom, 0.25)
    camera_tween.tween_property(camera, "global_position", player.global_position + normal_camera_position, 0.25)
    camera_tween.chain().tween_callback(func():
        camera.top_level = false
        camera.position = normal_camera_position
        camera.position_smoothing_enabled = normal_camera_smoothing
        camera.reset_smoothing()
    )

func trigger_death() -> void:
    _clear_seduction()
    super.trigger_death()

func _spawn_minions() -> void:
    state = State.MINIONS
    minions.clear()
    if is_instance_valid(trance_enemy) and trance_enemy.hp > 0:
        minions.append(trance_enemy)
    cycle_count += 1
    var count := 2 if boss.hp > boss.max_hp / 2 else 3
    var spawn_positions := [Vector2(145, 385), Vector2(450, 525), Vector2(340, 365)]
    for index in count:
        var minion = MINION_SCENE.instantiate()
        minion.name = "IaraMinion%d_%d" % [cycle_count, index]
        minion.position = spawn_positions[index]
        add_child(minion)
        minions.append(minion)
        _set_enemy_active(minion, false)
        _set_enemy_active(minion, true)

func _spawn_trance_enemy() -> void:
    trance_enemy = MINION_SCENE.instantiate()
    trance_enemy.name = "TranceEnemy%d" % (cycle_count + 1)
    trance_enemy.speed = 30.0
    trance_enemy.telegraphed_attacks = false
    trance_enemy.position = player.position + Vector2(-100, 0)
    add_child(trance_enemy)
    _set_enemy_active(trance_enemy, false)
    _set_enemy_active(trance_enemy, true)

func _water_is_active() -> bool:
    return state in [State.IDLE, State.PREPARING, State.CASTING, State.SEDUCING]

func _update_water(delta: float) -> void:
    var exposed: bool = _water_is_active() and player.position.x >= WATER_EDGE
    if not exposed:
        water_exposure = 0.0
        _restore_water_visual()
        return
    water_exposure += delta
    if not player.is_dodging:
        player.position = player.position.move_toward(WATER_POSITION, (15.0 + water_exposure * 8.0) * delta)
    _set_submersion(clampf(water_exposure / DROWNING_SECONDS, 0.0, 1.0))
    if water_exposure >= DROWNING_SECONDS:
        _finish_drowning()

func _begin_drowning() -> void:
    if state == State.DROWNING or finished or player.hp <= 0:
        return
    state = State.DROWNING
    state_timer = DROWNING_SECONDS
    _clear_seduction()
    player._end_dodge()
    player.control_locked = true
    player.set_physics_process(false)
    player.sprite.set_process(false)
    player.sprite.play("hurt")
    player.jump_height = 0.0
    player.jump_speed = 0.0
    drowning_start_position = player.position
    drowning_start_depth = clampf(water_exposure / DROWNING_SECONDS, 0.0, 1.0)
    _set_submersion(drowning_start_depth)
    veil.color.a = 0.18
    music.volume_db = original_music_volume - 12.0
    low_pass.cutoff_hz = 450.0
    if is_instance_valid(trance_enemy):
        _set_enemy_active(trance_enemy, false)

func _update_drowning() -> void:
    var progress := clampf(1.0 - state_timer / DROWNING_SECONDS, 0.0, 1.0)
    var eased := smoothstep(0.0, 1.0, progress)
    player.position = drowning_start_position.lerp(Vector2(850, 470), eased)
    # Preserve the silhouette: sinking is translation, never sprite compression.
    var struggle := sin(progress * TAU * 4.0) * (1.0 - eased)
    player.sprite.position = player.sprite_base_position + Vector2(struggle * 2.0, eased * 16.0)
    player.sprite.modulate = Color.WHITE.lerp(Color(0.65, 0.85, 1.0), eased)
    _set_submersion(lerpf(drowning_start_depth, 1.0, progress))
    veil.color.a = lerpf(0.18, 0.5, eased)
    low_pass.cutoff_hz = lerpf(850.0, 220.0, eased)
    music.volume_db = original_music_volume - lerpf(8.0, 16.0, eased)
    if state_timer <= 0.0:
        _finish_drowning()

func _finish_drowning() -> void:
    if player.hp <= 0:
        return
    # Environmental death ignores roll immunity and uses the standard death animation.
    state = State.DROWNING
    state_timer = 0.0
    _clear_seduction()
    player._end_dodge()
    player.dodge_protected_frame = -1
    player.damage_cooldown = 0.0
    player.control_locked = true
    player.sprite.scale = Vector2(0.9375, 0.9375)
    _set_submersion(1.0)
    corpse_elapsed = 0.0
    corpse_start_offset = player.sprite.position
    corpse_start_color = player.sprite.modulate
    player.sprite.set_process(true)
    player.take_damage(player.hp)

func _set_submersion(progress: float) -> void:
    if submersion_material == null:
        normal_player_material = player.sprite.material
        submersion_material = ShaderMaterial.new()
        submersion_material.shader = preload("res://shaders/drowning.gdshader")
    player.sprite.material = submersion_material
    player.shadow_opacity = 1.0 - smoothstep(0.0, 1.0, progress)
    player.queue_redraw()
    water_surface = player.position + Vector2(0.0, -lerpf(4.0, 48.0, smoothstep(0.0, 1.0, progress)))
    submersion_material.set_shader_parameter("surface_y", water_surface.y)
    submersion_material.set_shader_parameter("surface_x", water_surface.x)
    submersion_material.set_shader_parameter("phase", river_effects.clock)

func _restore_water_visual() -> void:
    if submersion_material != null and player.sprite.material == submersion_material:
        player.sprite.material = normal_player_material
        player.shadow_opacity = 1.0
        player.queue_redraw()

func _update_sinking_corpse(delta: float) -> void:
    corpse_elapsed = minf(CORPSE_SINK_SECONDS, corpse_elapsed + delta)
    var progress := smoothstep(0.0, 1.0, corpse_elapsed / CORPSE_SINK_SECONDS)
    # Move only the rendered body so the camera and the water surface stay steady.
    player.sprite.position = corpse_start_offset + Vector2(0.0, 65.0 * progress)
    player.sprite.modulate = Color(corpse_start_color, corpse_start_color.a * (1.0 - progress))

func iara_defeated() -> void:
    state = State.DEFEATED
    _clear_seduction()
    $HUD/BossHealth.value = 0
    resistance_bar.hide()
    preload("res://scripts/CampaignProgress.gd").complete_stage(stage_index)
    finished = true
    get_node("/root/SceneTransition").complete_level(self, next_stage_path)

func _update_hud() -> void:
    super._update_hud()
    $HUD/BossHealth.visible = not finished and is_instance_valid(boss)
    if resistance_bar == null:
        return
    resistance_bar.visible = state == State.SEDUCING
    resistance_bar.value = resistance
