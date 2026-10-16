extends "res://scripts/Level1.gd"

signal cuca_defeated

const ENEMY_SCENE := preload("res://scenes/Enemy.tscn")
const SCENERY := preload("res://scripts/CucaCaveScenery.gd")
const STALACTITE := preload("res://scripts/CaveStalactite.gd")
const STAGE_LENGTH := 5200.0
const STAGE_START := Vector2(180, 450)
const SECOND_STAGE_GATE := 1500.0
const THIRD_STAGE_GATE := 2940.0
const EXPLORATION_END_X := 4200.0
const SECTION_CHECKPOINTS := ["start", "trecho_2", "trecho_3"]

var cave_scenery: Node2D
var stalactites: Array[Node2D] = []
var section_label: Label
var exit_tween: Tween
var cuca_fight: Node2D
var boss_started := false
var boss_defeated := false
var restore_boss := false
var laboratory: Node2D
var cuca_health: ProgressBar
var cuca_name: Label
var boss_hint: Label
var result_panel: PanelContainer
var current_boss_hint := ""

func _ready() -> void:
    super._ready()
    cave_scenery = SCENERY.new()
    cave_scenery.setup(self)
    add_child(cave_scenery)
    _build_stalactites()
    _build_route_label()
    _build_boss_hud()
    laboratory = preload("res://scripts/CucaLaboratory.gd").new()
    laboratory.setup(self)
    add_child(laboratory)
    # Prepare atlas images and the counter icon while the stage is loading,
    # keeping the first boss entrance and first reflected skull smooth.
    preload("res://scripts/CucaFrames.gd").build(125.0)
    preload("res://scripts/CucaFrames.gd").ritual_frames(125.0)
    var key_warmup := preload("res://scripts/JaguarMashPrompt.gd").new()
    $HUD.add_child(key_warmup)
    key_warmup.queue_free()
    music.volume_db = -22.0
    _update_hud()
    queue_redraw()
    if restore_boss:
        call_deferred("_begin_cuca_encounter")

func _setup_encounters() -> void:
    # The only gap separates the second and third sections. Its full depth
    # prevents walking around it; the standard jump can clear its width.
    pits = [Rect2(2700, 325, 110, 255)]
    player.position = STAGE_START
    var camera := player.get_node("Camera2D") as Camera2D
    camera.limit_left = 0
    camera.limit_right = int(STAGE_LENGTH)
    camera.limit_top = 180
    camera.limit_bottom = 580
    $Enemy1.position = Vector2(610, 420)
    $Enemy2.position = Vector2(880, 510)
    $Enemy3.position = Vector2(1150, 450)
    $Enemy4.position = Vector2(1760, 420)
    waves = [
        [$Enemy1, $Enemy2, $Enemy3],
        [$Enemy4, _new_enemy("CaveEnemy5", Vector2(2100, 500)), _new_enemy("CaveEnemy6", Vector2(2460, 440))],
        [
            _new_enemy("CaveEnemy7", Vector2(3200, 420)),
            _new_enemy("CaveEnemy8", Vector2(3470, 510)),
            _new_enemy("CaveEnemy9", Vector2(3730, 430)),
            _new_enemy("CaveEnemy10", Vector2(4000, 490)),
        ],
    ]
    _set_section_bounds(0)

func _new_enemy(actor_name: String, point: Vector2) -> CharacterBody2D:
    var enemy := ENEMY_SCENE.instantiate() as CharacterBody2D
    enemy.name = actor_name
    enemy.position = point
    add_child(enemy)
    return enemy

func _build_stalactites() -> void:
    # Attach the rocks above the visible top edge (camera limit y=180).
    # Each unstable rock captures the hero's lane as they pass underneath.
    var placements := [
        [Vector2(310, 148), 450.0, false, 0],
        [Vector2(620, 156), 450.0, true, 0],
        [Vector2(1000, 144), 410.0, false, 0],
        [Vector2(1240, 152), 500.0, true, 0],
        [Vector2(1740, 148), 470.0, false, 1],
        [Vector2(1980, 155), 410.0, true, 1],
        [Vector2(2390, 148), 490.0, true, 1],
        [Vector2(2590, 142), 430.0, false, 1],
        [Vector2(3160, 152), 450.0, true, 2],
        [Vector2(3500, 144), 420.0, false, 2],
        [Vector2(3770, 155), 510.0, true, 2],
        [Vector2(4090, 148), 440.0, false, 2],
    ]
    for placement in placements:
        var rock := STALACTITE.new()
        rock.configure(self, placement[0], placement[1], placement[2], placement[3])
        add_child(rock)
        stalactites.append(rock)

func _set_section_bounds(section: int, open: bool = false) -> void:
    match section:
        0:
            arena_bounds = Rect2(40, 340, (2610.0 if open else 1380.0) - 40.0, 220)
        1:
            arena_bounds = Rect2(1450, 340, (4500.0 if open else 2610.0) - 1450.0, 220)
        _:
            arena_bounds = Rect2(2860, 340, 4500.0 - 2860.0, 220)

func _initialize_checkpoint() -> void:
    var saved: Dictionary = get_node("/root/SceneTransition").take_checkpoint(scene_file_path)
    var restored: bool = not saved.is_empty() and saved["stage"] == stage_index
    if restored:
        checkpoint_id = saved["id"]
        restore_boss = checkpoint_id == "boss"
        wave_index = 2 if checkpoint_id in ["trecho_3", "boss"] else 1 if checkpoint_id == "trecho_2" else 0
    _set_section_bounds(wave_index)
    for index in waves.size():
        for enemy in waves[index]:
            if index < wave_index or restore_boss:
                enemy.queue_free()
            elif index == wave_index:
                _set_enemy_active(enemy, true)
    if restored:
        player.position = saved["position"].clamp(arena_bounds.position, arena_bounds.end)
        if restore_boss:
            player.position = Vector2(4270, 460)
        for pit in pits:
            if pit.grow(28.0).has_point(player.position):
                player.position = Vector2(pit.end.x + 50.0, 450)
    player.last_safe_position = player.position
    player.get_node("Camera2D").reset_smoothing()
    _save_checkpoint(checkpoint_id, "Checkpoint retomado" if restored else "Checkpoint salvo")

func _process(delta: float) -> void:
    _update_hud()
    if finished or player.hp <= 0 or boss_intro_running or boss_started:
        return
    tutorial.advance(delta)
    if not _section_is_clear():
        return
    road_open = true
    _set_section_bounds(wave_index, true)
    if not _has_landed():
        return
    if wave_index == 0 and player.position.x >= SECOND_STAGE_GATE:
        _start_section(1)
    elif wave_index == 1 and player.position.x >= THIRD_STAGE_GATE:
        _start_section(2)
    elif wave_index == 2 and player.position.x >= EXPLORATION_END_X:
        _begin_cuca_encounter()

func _section_is_clear() -> bool:
    for enemy in waves[wave_index]:
        if is_instance_valid(enemy) and enemy.hp > 0:
            return false
    return true

func _has_landed() -> bool:
    return player.jump_height <= 0.0 and not player.is_falling

func _start_section(index: int) -> void:
    wave_index = index
    road_open = false
    _set_section_bounds(index)
    _save_checkpoint(SECTION_CHECKPOINTS[index])
    for enemy in waves[index]:
        _set_enemy_active(enemy, true)

func _build_route_label() -> void:
    section_label = Label.new()
    section_label.name = "CaveRoute"
    section_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    section_label.add_theme_font_size_override("font_size", 21)
    section_label.add_theme_color_override("font_color", Color("d9e6bb"))
    section_label.add_theme_color_override("font_shadow_color", Color(0.01, 0.02, 0.015, 0.95))
    section_label.add_theme_constant_override("shadow_offset_x", 1)
    section_label.add_theme_constant_override("shadow_offset_y", 2)
    $HUD.add_child(section_label)
    section_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    section_label.offset_left = -190
    section_label.offset_right = 190
    section_label.offset_top = 25
    section_label.offset_bottom = 87

func _update_hud() -> void:
    super._update_hud()
    $HUD/BossHealth.hide()
    if section_label == null:
        return
    if boss_started:
        section_label.text = "LABORATÓRIO DA CUCA"
        if is_instance_valid(cuca_health) and is_instance_valid(cuca_fight):
            cuca_health.visible = not boss_defeated
            cuca_name.visible = not boss_defeated
            boss_hint.visible = not boss_defeated
            cuca_health.max_value = cuca_fight.actor.max_hp
            cuca_health.value = cuca_fight.actor.hp
            var phase_names := ["O CALDEIRÃO", "MAGIA INSTÁVEL", "ÚLTIMO ENCANTAMENTO"]
            cuca_name.text = "CUCA  •  " + phase_names[clampi(cuca_fight.phase, 0, 2)]
            boss_hint.text = current_boss_hint
        return
    if finished:
        section_label.text = "NAS PROFUNDEZAS DA CAVERNA\nO rastro da Cuca segue adiante..."
        return
    var objective := "Abra caminho pela caverna"
    if road_open:
        objective = "Avance pela caverna"
        if wave_index == 1:
            objective = "Salte o abismo"
    section_label.text = "CAVERNA DA CUCA  •  %d / 3\n%s" % [wave_index + 1, objective]

func _begin_cuca_encounter() -> void:
    if boss_started or finished or player.hp <= 0 or not _has_landed():
        return
    boss_started = true
    road_open = false
    arena_bounds = Rect2(4160, 340, 890, 220)
    player.last_safe_position = Vector2(4270, 460)
    _save_checkpoint("boss")
    for rock in stalactites:
        rock.set_physics_process(false)
    cuca_fight = preload("res://scripts/CucaBossFight.gd").new()
    cuca_fight.name = "CucaBossFight"
    cuca_fight.setup(self)
    cuca_fight.hint_changed.connect(func(message: String): current_boss_hint = message)
    cuca_fight.defeated.connect(_on_cuca_defeated)
    add_child(cuca_fight)
    cuca_fight.start_encounter()
    _update_hud()

func _build_boss_hud() -> void:
    cuca_health = ProgressBar.new()
    cuca_health.name = "CucaHealth"
    cuca_health.show_percentage = false
    cuca_health.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var background := StyleBoxFlat.new()
    background.bg_color = Color("111914")
    background.border_color = Color("b89654")
    background.set_border_width_all(2)
    background.set_corner_radius_all(4)
    var fill := StyleBoxFlat.new()
    fill.bg_color = Color("8cb44e")
    fill.set_corner_radius_all(3)
    cuca_health.add_theme_stylebox_override("background", background)
    cuca_health.add_theme_stylebox_override("fill", fill)
    $HUD.add_child(cuca_health)
    cuca_health.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    cuca_health.offset_left = -300
    cuca_health.offset_right = 300
    cuca_health.offset_top = -49
    cuca_health.offset_bottom = -29
    cuca_health.hide()
    cuca_name = Label.new()
    cuca_name.name = "CucaName"
    cuca_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    cuca_name.add_theme_font_size_override("font_size", 22)
    cuca_name.add_theme_color_override("font_color", Color("ede1b4"))
    cuca_name.add_theme_color_override("font_shadow_color", Color.BLACK)
    cuca_name.add_theme_constant_override("shadow_offset_y", 2)
    $HUD.add_child(cuca_name)
    cuca_name.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    cuca_name.offset_left = -300
    cuca_name.offset_right = 300
    cuca_name.offset_top = -82
    cuca_name.offset_bottom = -50
    cuca_name.hide()
    boss_hint = Label.new()
    boss_hint.name = "CucaHint"
    boss_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    boss_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    boss_hint.add_theme_font_size_override("font_size", 19)
    boss_hint.add_theme_color_override("font_color", Color("dae8bb"))
    boss_hint.add_theme_color_override("font_shadow_color", Color.BLACK)
    boss_hint.add_theme_constant_override("shadow_offset_y", 2)
    $HUD.add_child(boss_hint)
    boss_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    boss_hint.offset_left = -290
    boss_hint.offset_right = 290
    boss_hint.offset_top = 65
    boss_hint.offset_bottom = 100
    boss_hint.hide()

func _on_cuca_defeated() -> void:
    if boss_defeated:
        return
    boss_defeated = true
    finished = true
    boss_intro_running = true
    player._end_dodge()
    player.control_locked = true
    player.velocity = Vector2.ZERO
    player.set_physics_process(false)
    player.sprite.set_process(false)
    player.sprite.position = player.sprite_base_position
    player.sprite.play("idle")
    _update_hud()
    cuca_defeated.emit()
    # Replace this aftermath panel with the user's final ritual cutscene.
    # Keep the boss checkpoint and campaign unlocks until that story exists.
    var ui := CanvasLayer.new()
    ui.layer = 8
    add_child(ui)
    result_panel = PanelContainer.new()
    result_panel.name = "CucaResult"
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.02, 0.045, 0.035, 0.94)
    style.border_color = Color("a88d4d")
    style.set_border_width_all(2)
    style.set_corner_radius_all(12)
    style.content_margin_left = 28
    style.content_margin_right = 28
    style.content_margin_top = 22
    style.content_margin_bottom = 22
    result_panel.add_theme_stylebox_override("panel", style)
    ui.add_child(result_panel)
    result_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    result_panel.offset_left = -240
    result_panel.offset_right = 240
    result_panel.offset_top = -95
    result_panel.offset_bottom = 170
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 12)
    result_panel.add_child(box)
    var title := Label.new()
    title.text = "CUCA DERROTADA"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color("f1dda1"))
    box.add_child(title)
    for label in ["Tentar novamente", "Voltar ao mapa"]:
        var button := Button.new()
        button.text = label
        button.custom_minimum_size = Vector2(400, 66)
        preload("res://scripts/GameMenu.gd").style_button(button)
        box.add_child(button)
        if label == "Tentar novamente":
            button.pressed.connect(_reset_scene)
        else:
            button.pressed.connect(func(): get_node("/root/SceneTransition").load_level(next_stage_path))
    box.get_child(1).grab_focus()
    result_panel.modulate.a = 0.0
    create_tween().tween_property(result_panel, "modulate:a", 1.0, 0.4)
