extends Node2D

const LEVEL_WIDTH := 3800.0
const PIT_TEXTURE := preload("res://sprites/buraco.png")
const PIT_DEATH_MARGIN := 6.0
const PIT_VISUAL_SIDE_MARGIN := 72.0

var pit_texture_region: Rect2

var arena_bounds := Rect2(40, 340, 860, 220)
var pits: Array[Rect2] = [Rect2(1060, 325, 100, 255), Rect2(2450, 325, 110, 255)]
var wave_index: int = 0
var finished: bool = false
var dodge_enemy_activated: bool = false
var road_open: bool = false
var waves: Array = []
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
    # Extend the repeating textures if the level width changes.
    for scenery: Sprite2D in [$Background, $Ground]:
        scenery.region_rect.size.x = LEVEL_WIDTH / scenery.scale.x
    add_to_group("game_manager")
    add_child(music)
    music.play_track("res://music/Fase1.mp3")
    var pause_menu = preload("res://scripts/GameMenu.gd").new()
    pause_menu.name = "PauseMenu"
    pause_menu.main_menu = false
    add_child(pause_menu)
    waves = [[$Enemy1, $Enemy2], [$Enemy3, $Enemy4], [$Boss]]
    for index in waves.size():
        for enemy in waves[index]:
            _set_enemy_active(enemy, index == 0 and enemy == $Enemy1)
    reset_button.pressed.connect(_reset_scene)
    _update_hud()

func _set_enemy_active(enemy: CharacterBody2D, active: bool) -> void:
    enemy.visible = active
    enemy.set_physics_process(active)
    enemy.collision_layer = 4 if active else 0
    enemy.collision_mask = 3 if active else 0
    enemy.get_node("DamageArea").monitoring = active
    enemy.get_node("HurtArea").collision_layer = 8 if active else 0

func _process(_delta: float) -> void:
    _update_hud()
    if finished or player.hp <= 0:
        return
    if wave_index == 0 and not dodge_enemy_activated and (not is_instance_valid(waves[0][0]) or waves[0][0].hp <= 0):
        dodge_enemy_activated = true
        if is_instance_valid(waves[0][1]):
            _set_enemy_active(waves[0][1], true)
    for enemy in waves[wave_index]:
        if is_instance_valid(enemy) and enemy.hp > 0:
            return
    if wave_index == waves.size() - 1:
        finished = true
        $DeathScreen/CenterContainer/VBoxContainer/Label.text = "Vitoria! Boitata derrotada"
        death_screen.visible = true
        reset_button.grab_focus()
        player.set_physics_process(false)
        return
    road_open = true
    var next_gate := 2300.0 if wave_index == 0 else 3760.0
    arena_bounds.size.x = next_gate - arena_bounds.position.x
    $HUD/WaveLabel.text = "Caminho aberto! Avance para a direita >>"
    var activation_x := 1500.0 if wave_index == 0 else 2900.0
    if player.position.x >= activation_x:
        wave_index += 1
        if wave_index == 2:
            music.play_track("res://music/Boitata.mp3")
        road_open = false
        for enemy in waves[wave_index]:
            _set_enemy_active(enemy, true)
        queue_redraw()

func _update_hud() -> void:
    health_bar.max_value = player.max_hp
    health_bar.value = player.hp
    health_label.text = "Vida: %d / %d" % [player.hp, player.max_hp]
    $HUD/AttackCooldown.value = 100.0 * (1.0 - player.attack_cooldown_timer / player.attack_cooldown)
    $HUD/DodgeCooldown.value = 100.0 * (1.0 - player.dodge_cooldown_timer / player.dodge_cooldown)
    $HUD/CooldownLabel.text = "K: %s | Shift: %s" % ["PRONTO" if player.attack_cooldown_timer <= 0 else "%.1fs" % player.attack_cooldown_timer, "PRONTO" if player.can_dodge else "%.1fs" % player.dodge_cooldown_timer]
    if finished or player.hp <= 0:
        return
    $HUD/WaveLabel.text = "Encontro %d / 3 - %s" % [wave_index + 1, "caminho aberto >>" if road_open else "derrote os inimigos"]
    var hint := ""
    if wave_index == 0 and not player.has_moved:
        hint = "1. MOVIMENTO: WASD ou setas para andar pela rua."
    elif wave_index == 0 and not dodge_enemy_activated and not road_open:
        hint = "2. ATAQUE: aproxime-se na mesma faixa e use K. Intervalo: 1s."
    elif wave_index == 0 and not road_open:
        hint = "3. ROLADA: a faixa amarela anuncia o golpe. Use Shift para atravessar o inimigo!"
    elif road_open:
        hint = "4. PULO: avance segurando D e aperte Espaco antes do buraco. Cair causa morte!"
    elif wave_index == 1:
        hint = "5. PROFUNDIDADE: use W/S para alinhar ataques e escapar das faixas amarelas."
    else:
        hint = "6. BOITATA: brilho anuncia investida! Saia da faixa ou role; ataque na recuperacao. Cuidado com mordida e cauda!"
    $HUD/TutorialLabel.text = hint
    $HUD/BossHealth.visible = wave_index == 2 and is_instance_valid(boss)
    if is_instance_valid(boss):
        $HUD/BossHealth.max_value = boss.max_hp
        $HUD/BossHealth.value = boss.hp

func trigger_death() -> void:
    death_screen.show_death()

func _reset_scene() -> void:
    get_tree().paused = false
    get_tree().reload_current_scene()

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
