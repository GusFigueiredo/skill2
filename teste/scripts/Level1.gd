extends Node2D

const LEVEL_WIDTH := 3800.0
const PIT_TEXTURE := preload("res://sprites/buraco.png")
const PIT_DEATH_MARGIN := 6.0
const PIT_VISUAL_SIDE_MARGIN := 72.0

@export var tutorial_stage := true
@export_file("*.tscn") var next_stage_path := "res://ratanaba2.tscn"
var boss_intro_running := false
var boss_intro_tween: Tween
var boss_entry_tween: Tween
var boss_landing_position := Vector2.ZERO
const BOSS_ENTRY_WALK_DISTANCE := 20.0
const BOSS_APPROACH_SECONDS := 1.8
const BOSS_REVEAL_SECONDS := 0.6
const AFTER_ROAR_SECONDS := 0.5
var boss_area_entered := false
var pit_texture_region: Rect2

var arena_bounds := Rect2(40, 340, 860, 220)
var pits: Array[Rect2] = [Rect2(1060, 325, 100, 255), Rect2(2450, 325, 110, 255)]
var wave_index: int = 0
var finished: bool = false
var dodge_enemy_activated: bool = false
var road_open: bool = false
var waves: Array = []
var tutorial: Control
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
    add_child(music)
    music.play_track("res://music/Fase1.mp3")
    var pause_menu = preload("res://scripts/GameMenu.gd").new()
    pause_menu.name = "PauseMenu"
    pause_menu.main_menu = false
    add_child(pause_menu)
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
        for enemy in waves[0]:
            _set_enemy_active(enemy, true)
    reset_button.pressed.connect(_reset_scene)
    _update_hud()

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
        preload("res://scripts/CampaignProgress.gd").complete_stage(0 if tutorial_stage else 1)
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
            _walk_into_boss_arena()
        return
    if player.position.x >= 1500.0:
        wave_index = 1
        road_open = false
        for enemy in waves[wave_index]:
            _set_enemy_active(enemy, true)
        queue_redraw()

func _walk_into_boss_arena() -> void:
    boss_intro_running = true
    music.stop()
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
    $HUD/WaveLabel.text = "\u00c1rea %d / %d - %s" % [ (1 if player.position.x < 1166 else 2) if tutorial_stage else wave_index + 1, 2 if tutorial_stage else 3, "caminho aberto >>" if road_open else "derrote os inimigos"]
    $HUD/BossHealth.visible = wave_index == 2 and not boss_intro_running and is_instance_valid(boss)
    if is_instance_valid(boss):
        $HUD/BossHealth.max_value = boss.max_hp
        $HUD/BossHealth.value = boss.hp

func trigger_death() -> void:
    death_screen.show_death()

func _reset_scene() -> void:
    get_tree().paused = false
    get_node("/root/SceneTransition").load_level("res://main.tscn" if tutorial_stage else "res://ratanaba2.tscn")

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
    add_child(camera)
    camera.global_position = initial_center
    camera.zoom = original.zoom
    camera.make_current()
    var roar := AudioStreamPlayer.new()
    roar.stream = preload("res://soundeffect/Boitata/rujido.mp3")
    add_child(roar)
    var roar_duration := maxf(0.1, roar.stream.get_length())
    boss_intro_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    # First travel along the road; then hold the dark idle silhouette in close-up.
    boss_intro_tween.tween_property(camera, "global_position", boss.global_position + Vector2(0, -100), BOSS_APPROACH_SECONDS)
    boss_intro_tween.parallel().tween_property(camera, "zoom", original.zoom * 1.4, BOSS_APPROACH_SECONDS)
    boss_intro_tween.tween_interval(BOSS_REVEAL_SECONDS)
    boss_intro_tween.tween_callback(func():
        visual.modulate = boss.body_color
        visual.play("bite")
        visual.set_frame_and_progress(0, 0.0)
        visual.pause()
        roar.play()
        entrance.roar()
        preload("res://scripts/CombatVFX.gd").spawn(boss, "eruption", boss.global_position + Vector2(0, -60), Vector2.RIGHT, Color("ffb23f"), 170.0)
    )
    boss_intro_tween.tween_method(func(elapsed: float): camera.offset = Vector2(sin(elapsed * 91.0), cos(elapsed * 73.0)) * 9.0 * (1.0 - elapsed / roar_duration), 0.0, roar_duration, roar_duration)
    boss_intro_tween.tween_callback(func():
        camera.offset = Vector2.ZERO
        visual.play("idle")
    )
    # The return to gameplay fills the requested half-second after the full roar.
    boss_intro_tween.tween_property(camera, "zoom", original.zoom, AFTER_ROAR_SECONDS)
    boss_intro_tween.parallel().tween_property(camera, "global_position", original.get_screen_center_position(), AFTER_ROAR_SECONDS)
    boss_intro_tween.tween_callback(func():
        original.make_current()
        camera.queue_free()
        entrance.queue_free()
        visual.modulate = boss.body_color
        visual.set_process(true)
        visual.play("idle")
        boss_intro_running = false
        player_visual.set_process(true)
        player.set_physics_process(true)
        _set_enemy_active(boss, true)
        music.play_track("res://music/Boitata.mp3")
    )
    roar.finished.connect(roar.queue_free)
