extends Node2D

var arena_bounds := Rect2(40, 340, 860, 220)
var pits: Array[Rect2] = [Rect2(1060, 325, 100, 255), Rect2(2450, 325, 110, 255)]
var wave_index: int = 0
var finished: bool = false
var dodge_enemy_activated: bool = false
var road_open: bool = false
var waves: Array = []
@onready var player = $Player
@onready var boss = $Boss
@onready var enemies: Array = [$Enemy1, $Enemy2]
@onready var health_bar: ProgressBar = $HUD/HealthBar
@onready var health_label: Label = $HUD/HealthLabel
@onready var death_screen: CanvasLayer = $DeathScreen
@onready var reset_button: Button = $DeathScreen/CenterContainer/VBoxContainer/ResetButton

func _ready() -> void:
    add_to_group("game_manager")
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
        player.set_physics_process(false)
        return
    road_open = true
    var next_gate := 2300.0 if wave_index == 0 else 3760.0
    arena_bounds.size.x = next_gate - arena_bounds.position.x
    $HUD/WaveLabel.text = "Caminho aberto! Avance para a direita >>"
    var activation_x := 1500.0 if wave_index == 0 else 2900.0
    if player.position.x >= activation_x:
        wave_index += 1
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
        hint = "6. BOITATA: saia da faixa amarela ou role no momento do golpe. Ataque durante a recuperacao!"
    $HUD/TutorialLabel.text = hint
    $HUD/BossHealth.visible = wave_index == 2 and is_instance_valid(boss)
    if is_instance_valid(boss):
        $HUD/BossHealth.max_value = boss.max_hp
        $HUD/BossHealth.value = boss.hp

func trigger_death() -> void:
    $DeathScreen/CenterContainer/VBoxContainer/Label.text = "Derrota"
    death_screen.visible = true

func _reset_scene() -> void:
    get_tree().reload_current_scene()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 3800, 720), Color("182537"))
    draw_rect(Rect2(0, 325, 3800, 255), Color("46505a"))
    for lane in [345, 450, 565]:
        draw_line(Vector2(0, lane), Vector2(3800, lane), Color("697580"), 2)
    for x in range(80, 3800, 160):
        draw_rect(Rect2(x, 180, 90, 120), Color("28394b"))
        draw_rect(Rect2(x + 18, 200, 24, 34), Color("947346"))
    for x in [920, 2320]:
        draw_line(Vector2(x, 325), Vector2(x, 580), Color("cfa65a"), 3)

    for pit in pits:
        draw_rect(pit, Color("090d16"))
        draw_rect(pit, Color("dca94b"), false, 4)
        for y in range(330, 575, 24):
            draw_line(Vector2(pit.position.x - 12, y), Vector2(pit.position.x - 3, y + 12), Color("f5cc64"), 4)
            draw_line(Vector2(pit.end.x + 3, y), Vector2(pit.end.x + 12, y + 12), Color("f5cc64"), 4)
        draw_string(ThemeDB.fallback_font, Vector2(pit.position.x - 145, 305), "BURACO - ESPACO PARA PULAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f5cc64"))

func check_player_floor(previous_position: Vector2) -> void:
    if player.jump_height > 0.0 or player.is_falling:
        return
    # Sweep the travelled path so a grounded roll cannot skip over a hole.
    var steps := maxi(1, ceili(previous_position.distance_to(player.position) / 4.0))
    for i in range(steps + 1):
        var point := previous_position.lerp(player.position, float(i) / steps)
        for pit in pits:
            if pit.grow(6).has_point(point):
                player.fall_into_pit()
                return
    var safe := true
    for pit in pits:
        if pit.grow(28).has_point(player.position):
            safe = false
    if safe:
        player.last_safe_position = player.position
