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
const STAGE_START := Vector2(180, 460)
const SECOND_STAGE_GATE := 1500.0
const SECOND_ARENA_END := 2700.0
const BOSS_ARENA_START := 3000.0
const BOSS_ENTRY_MIN_DISTANCE := 250.0
const BOSS_GATE := BOSS_ARENA_START + BOSS_ENTRY_MIN_DISTANCE
const BOSS_MUSIC_PATH := "res://music/Iara.mp3"
const APPROACH_MUSIC_MIN_VOLUME := 0.15
const APPROACH_MUSIC_FADE_END := SECOND_ARENA_END - 100.0
const WATER_EDGE := BOSS_ARENA_START + 620.0
const WATER_POSITION := Vector2(BOSS_ARENA_START + 780.0, 450)
const SHORE_POSITION := Vector2(BOSS_ARENA_START + 570.0, 450)
const BOSS_GROUND_TEXTURE := preload("res://sprites/cenario/Fases3e4/chao boss fight Iara.png")
const CHANT_AUDIO := preload("res://soundeffect/Iara/Canto.mp3")
const CHANT_MAX_VOLUME := 0.85
const MINION_SCENE := preload("res://scenes/RiverEnemy.tscn")

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
var entrance: Node
var sound_effects := preload("res://scripts/SoundEffects.gd").new()
var spell_sound_played := false
var spell_lead_seconds := 0.0
var chant: AudioStreamPlayer
var boss_ground: Sprite2D
var approach_music_volume := 0.0
var vitoria_leaf: AnimatedSprite2D
var vitoria_growth_tween: Tween
var rescue_running := false
var final_spell := false

func on_iara_damaged() -> void:
    if boss.hp <= boss.max_hp / 2 and vitoria_leaf == null:
        vitoria_leaf = AnimatedSprite2D.new()
        vitoria_leaf.name = "VitoriaRegiaPlant"
        var idle_texture: Texture2D = player.sprite.sprite_frames.get_frame_texture("idle", 0)
        var hero_height: float = idle_texture.get_image().get_used_rect().size.y * player.sprite.scale.y
        vitoria_leaf.sprite_frames = preload("res://scripts/VitoriaFrames.gd").build(hero_height)
        vitoria_leaf.offset = preload("res://scripts/VitoriaFrames.gd").grounded_offset(vitoria_leaf.sprite_frames)
        vitoria_leaf.play("plant")
        var leaf_position := WATER_POSITION + Vector2(100, 50)
        vitoria_leaf.position = leaf_position + Vector2(0, 12)
        vitoria_leaf.z_index = 2
        vitoria_leaf.scale = Vector2.ONE * 0.72
        vitoria_leaf.modulate.a = 0.0
        add_child(vitoria_leaf)
        vitoria_growth_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
        vitoria_growth_tween.tween_property(vitoria_leaf, "position", leaf_position, 1.2)
        vitoria_growth_tween.parallel().tween_property(vitoria_leaf, "scale", Vector2.ONE, 1.2)
        vitoria_growth_tween.parallel().tween_property(vitoria_leaf, "modulate:a", 1.0, 0.8)
    if boss.hp <= player.attack_damage and not final_spell:
        final_spell = true
        _start_cycle()

func _start_vitoria_rescue() -> void:
    if rescue_running:
        return
    rescue_running = true
    if is_instance_valid(vitoria_growth_tween):
        vitoria_growth_tween.kill()
    var rescue := preload("res://scripts/VitoriaRescue.gd").new()
    rescue.name = "VitoriaRescue"
    add_child(rescue)
    rescue.start(self)

func _setup_encounters() -> void:
    pits = [Rect2(1060, 325, 110, 255)]
    arena_bounds = Rect2(40, 345, 1000, 210)
    $Enemy1.position = Vector2(500, 395)
    $Enemy2.position = Vector2(880, 510)
    $Enemy3.position = Vector2(1660, 390)
    $Enemy4.position = Vector2(2110, 520)
    var extra = MINION_SCENE.instantiate()
    extra.name = "Enemy5"
    extra.position = Vector2(2490, 440)
    add_child(extra)
    waves = [[$Enemy1, $Enemy2], [$Enemy3, $Enemy4, extra], [boss]]
    boss.position = WATER_POSITION
    player.position = STAGE_START
    player.get_node("Camera2D").limit_right = 3850

static func boss_point(local_position: Vector2) -> Vector2:
    return local_position + Vector2(BOSS_ARENA_START, 0)

func _initialize_checkpoint() -> void:
    var saved: Dictionary = get_node("/root/SceneTransition").take_checkpoint(scene_file_path)
    var restored: bool = not saved.is_empty() and saved["stage"] == stage_index
    if restored:
        checkpoint_id = saved["id"]
        wave_index = 2 if checkpoint_id == "boss" else 1 if checkpoint_id == "wave_2" else 0
        if wave_index == 1:
            arena_bounds.size.x = SECOND_ARENA_END - arena_bounds.position.x
        elif wave_index == 2:
            arena_bounds = Rect2(BOSS_ARENA_START, 345, 1080, 210)
        player.position = saved["position"].clamp(arena_bounds.position, arena_bounds.end)
        if wave_index == 2:
            player.position.x = BOSS_GATE
        for previous_wave in range(wave_index):
            for enemy in waves[previous_wave]:
                enemy.queue_free()
    player.last_safe_position = player.position
    if wave_index < 2:
        for enemy in waves[wave_index]:
            _set_enemy_active(enemy, true)
    _save_checkpoint(checkpoint_id, "Checkpoint retomado" if restored else "Checkpoint salvo")

func _ready() -> void:
    super._ready()
    # The road continues into the original dry-bank/river composition at the boss.
    boss_ground = Sprite2D.new()
    boss_ground.name = "BossGround"
    boss_ground.texture = BOSS_GROUND_TEXTURE
    boss_ground.modulate = $Ground.modulate
    boss_ground.centered = false
    boss_ground.z_index = -1
    boss_ground.position = Vector2(BOSS_ARENA_START, 200)
    boss_ground.scale = Vector2($Ground.scale.x, 0.6)
    boss_ground.region_enabled = true
    boss_ground.region_rect = Rect2(0, 0, 1280.0 / boss_ground.scale.x, 1800.0 / boss_ground.scale.y)
    boss_ground.material = $Ground.material.duplicate()
    add_child(boss_ground)
    $Background.position.y = -80.0
    $Background.region_rect.position.y = 0.0
    var camera := player.get_node("Camera2D") as Camera2D
    normal_camera_zoom = camera.zoom
    normal_camera_position = camera.position
    normal_camera_smoothing = camera.position_smoothing_enabled
    # Keep the inherited 1.8 zoom, actor scales and player-following camera.
    camera.limit_right = 3850
    camera.reset_smoothing()
    $HUD/BossHealth/BossName.text = "IARA"
    _build_fight_feedback()
    _setup_river_audio()
    approach_music_volume = music.volume_linear
    _update_approach_music()
    add_child(sound_effects)
    sound_effects.setup({
        "spell": "res://soundeffect/Iara/Preprando e soltando ataque.mp3",
        "hit": "res://soundeffect/Iara/hit.mp3",
    })
    # Let the same short clip span the end of preparation and the spell launch.
    spell_lead_seconds = maxf(0.0, sound_effects.players["spell"].stream.get_length() - CAST_SECONDS * 0.5)
    _setup_chant()
    if checkpoint_id == "boss":
        _begin_boss_arena()
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
    var trance_screen := preload("res://scripts/TranceScreen.gd").new()
    trance_screen.fight = self
    overlay.add_child(trance_screen)
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
    _update_chant()
    _update_approach_music()
    if not boss_area_entered:
        _advance_approach()
        return
    if corpse_elapsed >= 0.0:
        _update_sinking_corpse(delta)
    if submersion_material != null and player.sprite.material == submersion_material:
        submersion_material.set_shader_parameter("phase", river_effects.clock)
    if camera_is_focused and state == State.SEDUCING and player.hp > 0:
        var camera := player.get_node("Camera2D") as Camera2D
        var target: Vector2 = player.global_position + player.combat_bounds.get_center()
        camera.global_position = camera.global_position.lerp(target, 1.0 - exp(-delta * 12.0))

func _physics_process(delta: float) -> void:
    if finished or player.hp <= 0 or boss_intro_running or rescue_running or not boss_area_entered:
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
            if not spell_sound_played and state_timer <= spell_lead_seconds:
                spell_sound_played = true
                sound_effects.play_effect("spell")
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

func _advance_approach() -> void:
    if finished or player.hp <= 0:
        return
    for enemy in waves[wave_index]:
        if is_instance_valid(enemy) and enemy.hp > 0:
            return
    road_open = true
    if wave_index == 0:
        arena_bounds.size.x = SECOND_ARENA_END - arena_bounds.position.x
        if player.position.x >= SECOND_STAGE_GATE and player.jump_height <= 0.0 and not player.is_falling:
            wave_index = 1
            road_open = false
            _save_checkpoint("wave_2")
            for enemy in waves[1]:
                _set_enemy_active(enemy, true)
            _update_chant()
    elif wave_index == 1:
        arena_bounds.size.x = BOSS_ARENA_START + 1080.0 - arena_bounds.position.x
        if player.position.x >= BOSS_GATE and player.jump_height <= 0.0 and not player.is_falling:
            _begin_boss_arena()
    queue_redraw()

func _begin_boss_arena() -> void:
    boss_area_entered = true
    wave_index = 2
    road_open = false
    arena_bounds = Rect2(BOSS_ARENA_START, 345, 1080, 210)
    player.position = player.position.clamp(arena_bounds.position, arena_bounds.end)
    var camera := player.get_node("Camera2D") as Camera2D
    camera.limit_left = int(BOSS_ARENA_START - 180.0)
    camera.reset_smoothing()
    _save_checkpoint("boss")
    _set_enemy_active(boss, true)
    chant.stop()
    entrance = preload("res://scripts/IaraEntrance.gd").new()
    add_child(entrance)
    entrance.start(self)

func _setup_chant() -> void:
    chant = AudioStreamPlayer.new()
    chant.name = "IaraDistantChant"
    chant.stream = CHANT_AUDIO.duplicate()
    chant.stream.loop = true
    chant.volume_linear = 0.0
    add_child(chant)
    _update_chant()

func _update_chant() -> void:
    if chant == null:
        return
    if boss_area_entered or finished or player.hp <= 0 or wave_index != 1 or player.position.x < SECOND_STAGE_GATE:
        chant.stop()
        chant.volume_linear = 0.0
        return
    var progress := clampf((player.position.x - SECOND_STAGE_GATE) / (BOSS_GATE - SECOND_STAGE_GATE), 0.0, 1.0)
    chant.volume_linear = progress * CHANT_MAX_VOLUME
    if not chant.playing:
        chant.play()

func _update_approach_music() -> void:
    if boss_area_entered or finished or player.hp <= 0:
        return
    var progress := clampf((player.position.x - SECOND_STAGE_GATE) / (APPROACH_MUSIC_FADE_END - SECOND_STAGE_GATE), 0.0, 1.0)
    music.volume_linear = approach_music_volume * lerpf(1.0, APPROACH_MUSIC_MIN_VOLUME, progress)

func _start_cycle() -> void:
    state = State.PREPARING
    state_timer = PREPARATION_SECONDS if boss.hp > boss.max_hp / 2 else 2.0
    preparation_duration = state_timer
    resistance = 0.0
    last_resistance_direction = 0
    water_exposure = 0.0
    spell_sound_played = false
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
    if not final_spell:
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
    if final_spell:
        resistance = minf(resistance, RESISTANCE_REQUIRED - 1.0)
        return
    if resistance >= RESISTANCE_REQUIRED:
        state = State.FALLING
        state_timer = FALL_SECONDS
        water_exposure = 0.0
        _clear_seduction()
        boss.get_node("Sprite").play("fall")

func seduction_pull_speed() -> float:
    return (120.0 if final_spell else 58.0) + (TRANSE_SECONDS - state_timer) * 4.0

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
    if boss_intro_running and entrance != null:
        entrance.abort()
    _clear_seduction()
    super.trigger_death()

func _spawn_minions() -> void:
    state = State.MINIONS
    minions.clear()
    if is_instance_valid(trance_enemy) and trance_enemy.hp > 0:
        minions.append(trance_enemy)
    cycle_count += 1
    var count := 2 if boss.hp > boss.max_hp / 2 else 3
    var spawn_positions := [boss_point(Vector2(145, 385)), boss_point(Vector2(450, 525)), boss_point(Vector2(340, 365))]
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
    return boss_area_entered and state in [State.IDLE, State.PREPARING, State.CASTING, State.SEDUCING]

func _update_water(delta: float) -> void:
    var exposed: bool = _water_is_active() and player.position.x >= WATER_EDGE
    if not exposed:
        water_exposure = 0.0
        _restore_water_visual()
        return
    if final_spell:
        _begin_drowning()
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
    player.position = drowning_start_position.lerp(boss_point(Vector2(850, 470)), eased)
    # Preserve the silhouette: sinking is translation, never sprite compression.
    var struggle := sin(progress * TAU * 4.0) * (1.0 - eased)
    player.sprite.position = player.sprite_base_position + Vector2(struggle * 2.0, eased * 16.0)
    player.sprite.modulate = Color.WHITE.lerp(Color(0.65, 0.85, 1.0), eased)
    _set_submersion(lerpf(drowning_start_depth, 1.0, progress))
    veil.color.a = lerpf(0.18, 0.5, eased)
    low_pass.cutoff_hz = lerpf(850.0, 220.0, eased)
    music.volume_db = original_music_volume - lerpf(8.0, 16.0, eased)
    if final_spell and progress >= 0.9:
        _start_vitoria_rescue()
        return
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

func iara_defeated(rescue_camera: Camera2D = null, leaf_route: Array[Vector2] = []) -> void:
    state = State.DEFEATED
    _clear_seduction()
    $HUD/BossHealth.value = 0
    resistance_bar.hide()
    preload("res://scripts/CampaignProgress.gd").complete_stage(stage_index)
    finished = true
    get_node("/root/SceneTransition").complete_level(self, next_stage_path, rescue_camera, leaf_route)

func _update_hud() -> void:
    super._update_hud()
    $HUD/BossHealth.visible = boss_area_entered and not finished and not boss_intro_running and is_instance_valid(boss)
    if resistance_bar == null:
        return
    resistance_bar.visible = state == State.SEDUCING
    resistance_bar.value = resistance
