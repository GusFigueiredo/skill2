extends Node2D

const LEVEL_WIDTH := 3800.0
const PIT_TEXTURE := preload("res://sprites/buraco.png")
const PIT_DEATH_MARGIN := 6.0
const PIT_VISUAL_SIDE_MARGIN := 72.0

@export var tutorial_stage := true
@export_range(0, 6) var stage_index := 0
@export_file("*.tscn") var next_stage_path := "res://ratanaba2.tscn"
@export_file("*.mp3") var level_music_path := "res://music/Fase1.mp3"
var boss_intro_running := false
var boss_intro_tween: Tween
var boss_entry_tween: Tween
var boss_landing_position := Vector2.ZERO
var boss_intro_hud_visible := true
const BOSS_ENTRY_WALK_DISTANCE := 20.0
const BOSS_APPROACH_SECONDS := 1.8
const BOSS_REVEAL_SECONDS := 0.6
const AFTER_ROAR_SECONDS := 0.5
const BOSS_CLOSEUP_ZOOM_FACTOR := 1.4
var boss_area_entered := false
var pit_texture_region: Rect2
var checkpoint_id := "start"
var checkpoint_notice: Label
var checkpoint_notice_tween: Tween

var arena_bounds := Rect2(40, 340, 860, 220)
var pits: Array[Rect2] = [Rect2(1060, 325, 100, 255), Rect2(2450, 325, 110, 255)]
var wave_index: int = 0
var finished: bool = false
var dodge_enemy_activated: bool = false
var road_open: bool = false
var waves: Array = []
var tutorial: Control
var ambience := preload("res://scripts/BossAmbience.gd").new()
var music := preload("res://scripts/MusicPlayer.gd").new()
@onready var player = $Player
@onready var boss = $Boss
@onready var enemies: Array = [$Enemy1, $Enemy2]
@onready var health_bar: ProgressBar = $HUD/HealthBar
@onready var health_label: Label = $HUD/HealthLabel
@onready var death_screen: CanvasLayer = $DeathScreen
@onready var reset_button: Button = $DeathScreen/CenterContainer/VBoxContainer/ResetButton

func _ready() -> void:
    preload("res://scripts/Presentation.gd").setup(self)
    # Fit the visible art, excluding the source image's transparent padding.
    pit_texture_region = Rect2(PIT_TEXTURE.get_image().get_used_rect())
    # Cover the full cinematic view while keeping the road and texture origin aligned.
    for scenery: Sprite2D in [$Background, $Ground]:
        var top := -1200.0 if scenery == $Background else 200.0
        scenery.position = Vector2(-1600, top)
        scenery.region_rect = Rect2(-1600.0 / scenery.scale.x, top / scenery.scale.y if scenery == $Background else 0.0, (LEVEL_WIDTH + 3200.0) / scenery.scale.x, (2000.0 - top) / scenery.scale.y)
        var extension := ShaderMaterial.new()
        extension.shader = preload("res://shaders/scenery_extension.gdshader")
        scenery.material = extension
        scenery.region_filter_clip_enabled = false
    add_to_group("game_manager")
    add_child(ambience)
    add_child(music)
    music.play_track(level_music_path)
    var pause_menu = preload("res://scripts/GameMenu.gd").new()
    pause_menu.name = "PauseMenu"
    pause_menu.main_menu = false
    add_child(pause_menu)
    _setup_encounters()
    for enemy in [$Enemy1, $Enemy2, $Enemy3, $Enemy4, $Boss]:
        _set_enemy_active(enemy, false)
    for index in waves.size():
        for enemy in waves[index]:
            _set_enemy_active(enemy, false)
    tutorial = preload("res://scripts/TutorialBalloon.gd").new()
    $HUD.add_child(tutorial)
    tutorial.setup(self)
    if not tutorial_stage:
        tutorial.step = tutorial.Step.COMPLETE
        tutorial.hide()
    reset_button.pressed.connect(_reset_scene)
    _initialize_checkpoint()
    _update_hud()
    if stage_index in [0, 1, 2, 3]:
        add_child(preload("res://scripts/StageScenery.gd").new())

func _initialize_checkpoint() -> void:
    var saved: Dictionary = get_node("/root/SceneTransition").take_checkpoint(scene_file_path)
    var restored: bool = not saved.is_empty() and saved["stage"] == stage_index
    if restored:
        checkpoint_id = saved["id"]
        if stage_index == 1 and checkpoint_id != "start":
            wave_index = 2 if checkpoint_id == "boss" else 1
            arena_bounds.size.x = (3760.0 if wave_index == 2 else 2300.0) - arena_bounds.position.x
            for previous_wave in range(wave_index):
                for enemy in waves[previous_wave]:
                    enemy.queue_free()
        player.position = saved["position"].clamp(arena_bounds.position, arena_bounds.end)
        # Keep a malformed/stale save away from the holes and the Iara's water.
        for pit in pits:
            if pit.grow(28.0).has_point(player.position):
                player.position.x = minf(arena_bounds.end.x, pit.end.x + 40.0)
        if stage_index == 3:
            player.position.x = minf(player.position.x, 440.0)
        player.last_safe_position = player.position
        player.get_node("Camera2D").reset_smoothing()
    if tutorial_stage and checkpoint_id == "tutorial_combat":
        tutorial.step = tutorial.Step.ATTACK
        tutorial._show_step()
        tutorial.previous_position = player.position
        tutorial._start_enemy_arrival()
    elif stage_index == 1 and checkpoint_id == "boss":
        boss_area_entered = true
        boss_landing_position = player.position
        _walk_into_boss_arena()
    elif not tutorial_stage:
        for enemy in waves[wave_index]:
            _set_enemy_active(enemy, true)
    _save_checkpoint(checkpoint_id, "Checkpoint retomado" if restored else "Checkpoint salvo")

func _save_checkpoint(next_id: String, message: String = "Checkpoint salvo") -> void:
    checkpoint_id = next_id
    var respawn_position: Vector2 = player.position
    for pit in pits:
        if pit.grow(28.0).has_point(respawn_position):
            respawn_position.x = pit.end.x + 40.0
    preload("res://scripts/CampaignProgress.gd").save_checkpoint(stage_index, checkpoint_id, respawn_position)
    if checkpoint_notice == null:
        checkpoint_notice = Label.new()
        checkpoint_notice.name = "CheckpointNotice"
        checkpoint_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
        checkpoint_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        checkpoint_notice.add_theme_font_size_override("font_size", 20)
        checkpoint_notice.add_theme_color_override("font_color", Color("efcd85"))
        checkpoint_notice.add_theme_color_override("font_shadow_color", Color.BLACK)
        checkpoint_notice.add_theme_constant_override("shadow_offset_x", 2)
        checkpoint_notice.add_theme_constant_override("shadow_offset_y", 2)
        $HUD.add_child(checkpoint_notice)
        checkpoint_notice.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
        checkpoint_notice.offset_left = -300
        checkpoint_notice.offset_top = 24
        checkpoint_notice.offset_right = -24
        checkpoint_notice.offset_bottom = 55
    if checkpoint_notice_tween != null and checkpoint_notice_tween.is_valid():
        checkpoint_notice_tween.kill()
    checkpoint_notice.text = message
    checkpoint_notice.modulate.a = 1.0
    checkpoint_notice_tween = create_tween()
    checkpoint_notice_tween.tween_interval(2.5)
    checkpoint_notice_tween.tween_property(checkpoint_notice, "modulate:a", 0.0, 0.5)

func _setup_encounters() -> void:
    if tutorial_stage:
        pits = [Rect2(1060, 325, 100, 255)]
        waves = [[$Enemy1, $Enemy2]]
        arena_bounds.size.x = 2260
        $Enemy1.position = Vector2(1560, 430)
        $Enemy2.position = Vector2(2000, 510)
        player.get_node("Camera2D").limit_right = 2300
    else:
        pits = [Rect2(2450, 325, 110, 255)]
        var extra = $Enemy4.duplicate()
        extra.name = "Enemy5"
        extra.position = Vector2(2180, 450)
        add_child(extra)
        waves = [[$Enemy1, $Enemy2], [$Enemy3, $Enemy4, extra], [$Boss]]

func _set_enemy_active(enemy: CharacterBody2D, active: bool) -> void:
    if active and not enemy.spawn_finished:
        enemy.play_spawn_animation(func(): _set_enemy_active(enemy, true))
        return
    enemy.visible = active
    enemy.set_physics_process(active)
    enemy.collision_layer = 4 if active else 0
    enemy.collision_mask = 3 if active else 0
    enemy.get_node("DamageArea").monitoring = active
    enemy.get_node("HurtArea").collision_layer = 8 if active else 0

func _process(_delta: float) -> void:
    _update_hud()
    if finished or player.hp <= 0 or boss_intro_running:
        return
    tutorial.advance(_delta)
    if tutorial_stage and (tutorial.step < tutorial.Step.ATTACK or tutorial.introducing_enemy):
        return
    if tutorial_stage and wave_index == 0 and not dodge_enemy_activated and (not is_instance_valid(waves[0][0]) or waves[0][0].hp <= 0):
        dodge_enemy_activated = true
        if is_instance_valid(waves[0][1]):
            _set_enemy_active(waves[0][1], true)
    for enemy in waves[wave_index]:
        if is_instance_valid(enemy) and enemy.hp > 0:
            return
    if wave_index == waves.size() - 1:
        if tutorial_stage and tutorial.step != tutorial.Step.COMPLETE:
            return
        preload("res://scripts/CampaignProgress.gd").complete_stage(stage_index)
        finished = true
        get_node("/root/SceneTransition").complete_level(self, next_stage_path)
        return
    road_open = true
    var next_gate := 2300.0 if wave_index == 0 else 3760.0
    arena_bounds.size.x = next_gate - arena_bounds.position.x
    $HUD/WaveLabel.text = "Caminho aberto! Avance para a direita >>"
    if wave_index == 1:
        if not boss_area_entered and player.position.x > pits[0].end.x + PIT_DEATH_MARGIN and player.jump_height <= 0.0 and not player.is_falling:
            boss_area_entered = true
            boss_landing_position = player.position
            wave_index = 2
            road_open = false
            _save_checkpoint("boss")
            _walk_into_boss_arena()
        return
    if player.position.x >= 1500.0:
        wave_index = 1
        road_open = false
        _save_checkpoint("wave_2")
        for enemy in waves[wave_index]:
            _set_enemy_active(enemy, true)
        queue_redraw()

func _walk_into_boss_arena() -> void:
    boss_intro_hud_visible = $HUD.visible
    $HUD.hide()
    boss_intro_running = true
    music.stop()
    ambience.begin()
    $HUD/BossHealth.hide()
    player.set_physics_process(false)
    player.velocity = Vector2.ZERO
    player.facing = 1
    player.is_dodging = false
    var visual := player.get_node("Sprite") as AnimatedSprite2D
    visual.set_process(false)
    visual.flip_h = false
    visual.play("walk")
    boss_entry_tween = create_tween()
    boss_entry_tween.tween_property(player, "position:x", boss_landing_position.x + BOSS_ENTRY_WALK_DISTANCE, BOSS_ENTRY_WALK_DISTANCE / maxf(1.0, player.speed))
    boss_entry_tween.tween_callback(func():
        visual.play("idle")
        _start_boss_intro()
    )

func _update_hud() -> void:
    health_bar.max_value = player.max_hp
    health_bar.value = player.hp
    health_label.text = "Vida: %d / %d" % [player.hp, player.max_hp]
    $HUD/AttackCooldown.value = 100.0 * (1.0 - player.attack_cooldown_timer / player.attack_cooldown)
    $HUD/DodgeCooldown.value = 100.0 * (1.0 - player.dodge_cooldown_timer / player.dodge_cooldown)
    $HUD/CooldownLabel.text = "K: %s | Shift: %s" % ["PRONTO" if player.attack_cooldown_timer <= 0 else "%.1fs" % player.attack_cooldown_timer, "PRONTO" if player.can_dodge else "%.1fs" % player.dodge_cooldown_timer]
    if finished or player.hp <= 0:
        return
    $HUD/WaveLabel.text = "\u00c1rea %d / %d - %s" % [ (1 if player.position.x < 1166 else 2) if tutorial_stage else wave_index + 1, 2 if tutorial_stage else waves.size(), "caminho aberto >>" if road_open else "derrote os inimigos"]
    $HUD/BossHealth.visible = wave_index == 2 and not boss_intro_running and is_instance_valid(boss)
    if is_instance_valid(boss):
        $HUD/BossHealth.max_value = boss.max_hp
        $HUD/BossHealth.value = boss.hp

func trigger_death() -> void:
    death_screen.show_death()

func _reset_scene() -> void:
    get_tree().paused = false
    get_node("/root/SceneTransition").load_level(scene_file_path, true)

func _draw() -> void:
    for pit in pits:
        var visual_rect := pit.grow_individual(PIT_VISUAL_SIDE_MARGIN, PIT_DEATH_MARGIN, PIT_VISUAL_SIDE_MARGIN, PIT_DEATH_MARGIN)
        draw_texture_rect_region(PIT_TEXTURE, visual_rect, pit_texture_region)

func check_player_floor(previous_position: Vector2) -> void:
    if player.jump_height > 0.0 or player.is_falling:
        return
    # Sweep the travelled path so a grounded roll cannot skip over a hole.
    var steps := maxi(1, ceili(previous_position.distance_to(player.position) / 4.0))
    for i in range(steps + 1):
        var point := previous_position.lerp(player.position, float(i) / steps)
        for pit in pits:
            if _pit_death_rect(pit).has_point(point):
                player.fall_into_pit()
                return
    var safe := true
    for pit in pits:
        if pit.grow(28).has_point(player.position):
            safe = false
    if safe:
        player.last_safe_position = player.position

func _pit_death_rect(pit: Rect2) -> Rect2:
    return pit.grow(PIT_DEATH_MARGIN)

func _start_boss_intro() -> void:
    if finished:
        return
    if not boss_intro_running:
        boss_intro_hud_visible = $HUD.visible
    $HUD.hide()
    boss_intro_running = true
    $HUD/BossHealth.hide()
    music.stop()
    var entrance := preload("res://scripts/BossEntrance.gd").new()
    add_child(entrance)
    player.velocity = Vector2.ZERO
    player.set_physics_process(false)
    # Spawn beyond one full view from the landing point, plus the 20-pixel entry.
    var original := player.get_node("Camera2D") as Camera2D
    original.reset_smoothing()
    original.force_update_scroll()
    var initial_center := original.get_screen_center_position()
    var view_width := get_viewport_rect().size.x / original.zoom.x
    var left_edge: float = boss.combat_bounds.position.x
    var right_of_view := initial_center.x + view_width * 0.5
    boss.position.x = maxf(boss_landing_position.x + view_width + BOSS_ENTRY_WALK_DISTANCE, right_of_view - left_edge + BOSS_ENTRY_WALK_DISTANCE)
    boss.position.y = player.position.y
    var required_right: float = boss.position.x + boss.combat_bounds.end.x + 40.0
    arena_bounds.size.x = maxf(arena_bounds.end.x, required_right) - arena_bounds.position.x
    boss.home_bounds.size.x = maxf(boss.home_bounds.end.x, arena_bounds.end.x) - boss.home_bounds.position.x
    original.limit_right = maxi(original.limit_right, ceili(arena_bounds.end.x))
    boss.visible = true
    boss.spawn_started = true
    boss.spawn_finished = true
    var visual := boss.get_node("Sprite") as AnimatedSprite2D
    visual.set_process(false)
    visual.flip_h = true
    visual.modulate = Color(0.25, 0.25, 0.25, 1.0)
    visual.play("idle")
    var player_visual := player.get_node("Sprite") as AnimatedSprite2D
    player_visual.set_process(false)
    player_visual.flip_h = false
    player_visual.play("idle")
    var camera := Camera2D.new()
    camera.limit_left = original.limit_left
    camera.limit_top = original.limit_top
    camera.limit_right = original.limit_right
    camera.limit_bottom = original.limit_bottom
    add_child(camera)
    camera.global_position = initial_center
    camera.zoom = original.zoom
    camera.make_current()
    var closeup_zoom := original.zoom * BOSS_CLOSEUP_ZOOM_FACTOR
    # Compose around the opaque art, with a little room in front of her gaze.
    var boss_center: Vector2 = boss.global_position + boss.combat_bounds.get_center()
    var closeup_focus := boss_center + Vector2(-28.0, -8.0)
    camera.limit_right = maxi(camera.limit_right, ceili(closeup_focus.x + get_viewport_rect().size.x / closeup_zoom.x * 0.5 + 48.0))
    var fire_glow := FlameReveal.new()
    fire_glow.name = "BoitataIntroFlames"
    fire_glow.character_size = boss.combat_bounds.size
    fire_glow.z_index = 1
    add_child(fire_glow)
    fire_glow.global_position = boss.global_position
    var roar := AudioStreamPlayer.new()
    roar.stream = preload("res://soundeffect/Boitata/rujido.mp3")
    roar.volume_db = 8.0
    add_child(roar)
    var roar_duration := maxf(0.1, roar.stream.get_length())
    boss_intro_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
    # Keep the camera inside the road while its view shrinks along a shallow arc.
    boss_intro_tween.tween_method(func(progress: float):
        camera.zoom = original.zoom.lerp(closeup_zoom * 0.97, progress)
        camera.global_position = _boss_intro_focus(initial_center.lerp(closeup_focus, progress) + Vector2(0, -sin(PI * progress) * 8.0), camera)
        fire_glow.clock = progress * BOSS_APPROACH_SECONDS
        fire_glow.strength = smoothstep(0.45, 1.0, progress) * 0.3
        fire_glow.queue_redraw()
    , 0.0, 1.0, BOSS_APPROACH_SECONDS)
    boss_intro_tween.tween_callback(func(): entrance.set_title("BOITATÁ", "GUARDIÃ DA FLORESTA"))
    boss_intro_tween.tween_method(func(progress: float):
        camera.zoom = (closeup_zoom * 0.97).lerp(closeup_zoom, progress)
        camera.global_position = _boss_intro_focus(closeup_focus, camera)
        fire_glow.clock = BOSS_APPROACH_SECONDS + progress * BOSS_REVEAL_SECONDS
        fire_glow.strength = lerpf(0.3, 0.65, progress)
        fire_glow.queue_redraw()
        entrance.accent_strength = progress * 0.45
    , 0.0, 1.0, BOSS_REVEAL_SECONDS)
    boss_intro_tween.tween_callback(func():
        visual.play("bite")
        visual.set_frame_and_progress(0, 0.0)
        visual.pause()
        ambience.duck()
        roar.play()
        entrance.roar()
        preload("res://scripts/CombatVFX.gd").spawn(boss, "embers", boss.global_position + Vector2(-25, -15), Vector2.RIGHT, Color("ffb23f"), 48.0)
    )
    boss_intro_tween.tween_method(func(elapsed: float):
        var progress := elapsed / roar_duration
        # A brief impulse settles quickly; the slow push keeps the reveal alive.
        camera.offset = Vector2(sin(elapsed * 36.0), cos(elapsed * 28.0)) * 3.2 * pow(1.0 - progress, 2.0)
        camera.zoom = closeup_zoom * lerpf(1.0, 1.025, smoothstep(0.0, 1.0, progress))
        camera.global_position = _boss_intro_focus(closeup_focus, camera)
        fire_glow.clock = BOSS_APPROACH_SECONDS + BOSS_REVEAL_SECONDS + elapsed
        fire_glow.strength = lerpf(1.0, 0.25, smoothstep(0.0, 1.0, progress))
        fire_glow.queue_redraw()
        entrance.accent_strength = fire_glow.strength * 0.65
    , 0.0, roar_duration, roar_duration).set_trans(Tween.TRANS_LINEAR)
    boss_intro_tween.parallel().tween_property(visual, "modulate", boss.body_color, minf(0.35, roar_duration))
    boss_intro_tween.tween_callback(func():
        camera.offset = Vector2.ZERO
        visual.play("idle")
        entrance.dismiss(AFTER_ROAR_SECONDS)
    )
    # The return to gameplay fills the requested half-second after the full roar.
    boss_intro_tween.tween_property(camera, "zoom", original.zoom, AFTER_ROAR_SECONDS)
    boss_intro_tween.parallel().tween_property(camera, "global_position", original.get_screen_center_position(), AFTER_ROAR_SECONDS)
    boss_intro_tween.parallel().tween_property(fire_glow, "modulate:a", 0.0, AFTER_ROAR_SECONDS)
    boss_intro_tween.tween_callback(func():
        original.make_current()
        camera.queue_free()
        entrance.queue_free()
        fire_glow.queue_free()
        visual.modulate = boss.body_color
        visual.set_process(true)
        visual.play("idle")
        boss_intro_running = false
        $HUD.visible = boss_intro_hud_visible
        player_visual.set_process(true)
        player.set_physics_process(true)
        _set_enemy_active(boss, true)
        ambience.end()
        music.play_track("res://music/Boitata.mp3")
    )
    roar.finished.connect(roar.queue_free)

func _boss_intro_focus(point: Vector2, camera: Camera2D) -> Vector2:
    var half_view := get_viewport_rect().size / (camera.zoom * 2.0)
    point.x = clampf(point.x, camera.limit_left + half_view.x, camera.limit_right - half_view.x)
    point.y = clampf(point.y, camera.limit_top + half_view.y, camera.limit_bottom - half_view.y)
    return point

class FlameReveal extends Node2D:
    var clock := 0.0
    var strength := 0.0
    var character_size := Vector2(200, 170)

    func _draw() -> void:
        if strength <= 0.001:
            return
        # Only a faint ground glow and a handful of small, square embers.
        draw_set_transform(Vector2(0, -3), 0, Vector2(1, 0.2))
        for i in range(3):
            draw_circle(Vector2.ZERO, character_size.x * (0.32 + i * 0.06), Color(1.0, 0.37, 0.055, strength * (0.035 - i * 0.008)))
        draw_set_transform(Vector2.ZERO)
        for i in range(18):
            var progress := fmod(clock * (0.45 + float(i % 4) * 0.08) + float(i) / 18.0, 1.0)
            var side := -1.0 if i % 2 == 0 else 1.0
            var x := side * character_size.x * (0.28 + float(i % 3) * 0.065)
            var point := Vector2(x + sin(progress * TAU + i * 0.9) * 7.0, -progress * character_size.y * 0.9).round()
            var alpha := sin(progress * PI) * strength
            draw_circle(point, 3.5, Color(1.0, 0.35, 0.04, alpha * 0.08))
            draw_rect(Rect2(point, Vector2.ONE * (1.0 + i % 2)), Color(1.0, 0.74, 0.25, alpha * 0.75))
