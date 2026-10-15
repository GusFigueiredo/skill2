extends "res://scripts/Level1.gd"

const Progress := preload("res://scripts/CampaignProgress.gd")
const ENEMY_SCENE := preload("res://scenes/Enemy.tscn")
const SCENERY := preload("res://scripts/CucaForestScenery.gd")
const STAGE_LENGTH := 4400.0
const STAGE_START := Vector2(180, 450)
const SECOND_STAGE_GATE := 1420.0
const THIRD_STAGE_GATE := 2780.0
const CAVE_DOOR := SCENERY.CAVE_DOOR
const CAVE_TRIGGER_X := SCENERY.CAVE_TRIGGER.x
const CAVE_CHECKPOINT_X := 3580.0
const CAVE_WALK_SPEED := 180.0
const SECTION_CHECKPOINTS := ["start", "trecho_2", "trecho_3"]

var cave_ready := false
var cave_entering := false
var cave_entry_tween: Tween
var cave_approach_seconds := 0.0
var cave_camera: Camera2D
var cave_fade: ColorRect
var section_label: Label
var forest_scenery: Node2D
var forest_ambience: AudioStreamPlayer

func _ready() -> void:
    super._ready()
    forest_scenery = SCENERY.new()
    forest_scenery.setup(self)
    add_child(forest_scenery)
    forest_ambience = AudioStreamPlayer.new()
    forest_ambience.name = "ForestAmbience"
    var ambience_track := preload("res://soundeffect/Feedback/forest.wav").duplicate() as AudioStreamWAV
    ambience_track.loop_mode = AudioStreamWAV.LOOP_FORWARD
    ambience_track.loop_begin = 0
    ambience_track.loop_end = roundi(ambience_track.get_length() * ambience_track.mix_rate)
    forest_ambience.stream = ambience_track
    forest_ambience.volume_db = -22.0
    add_child(forest_ambience)
    forest_ambience.play()
    _build_route_label()
    _update_hud()
    queue_redraw()

func _setup_encounters() -> void:
    pits = [Rect2(1200, 325, 110, 255)]
    player.position = STAGE_START
    var camera := player.get_node("Camera2D") as Camera2D
    camera.limit_left = 0
    camera.limit_right = int(STAGE_LENGTH)
    camera.limit_top = 180
    camera.limit_bottom = 580
    $Enemy1.position = Vector2(600, 420)
    $Enemy2.position = Vector2(830, 500)
    $Enemy3.position = Vector2(1010, 400)
    $Enemy4.position = Vector2(1770, 410)
    var second := [$Enemy4, _new_enemy("ForestEnemy5", Vector2(2090, 500)), _new_enemy("ForestEnemy6", Vector2(2440, 445))]
    var third := [
        _new_enemy("ForestEnemy7", Vector2(3070, 420)),
        _new_enemy("ForestEnemy8", Vector2(3350, 500)),
        _new_enemy("ForestEnemy9", Vector2(3560, 400)),
        _new_enemy("ForestEnemy10", Vector2(3850, 490)),
    ]
    waves = [[$Enemy1, $Enemy2, $Enemy3], second, third]
    _set_section_bounds(0)

func _new_enemy(actor_name: String, point: Vector2) -> CharacterBody2D:
    var enemy := ENEMY_SCENE.instantiate() as CharacterBody2D
    enemy.name = actor_name
    enemy.position = point
    add_child(enemy)
    return enemy

func _set_section_bounds(section: int, open: bool = false) -> void:
    match section:
        0:
            arena_bounds = Rect2(40, 340, (2600.0 if open else 1120.0) - 40.0, 220)
        1:
            arena_bounds = Rect2(1345, 340, (4300.0 if open else 2600.0) - 1345.0, 220)
        _:
            arena_bounds = Rect2(2715, 340, 4300.0 - 2715.0, 220)

func _initialize_checkpoint() -> void:
    var saved: Dictionary = get_node("/root/SceneTransition").take_checkpoint(scene_file_path)
    var restored: bool = not saved.is_empty() and saved["stage"] == stage_index
    if restored:
        checkpoint_id = saved["id"]
        wave_index = 2 if checkpoint_id in ["trecho_3", "caverna"] else 1 if checkpoint_id == "trecho_2" else 0
        cave_ready = checkpoint_id == "caverna"
    _set_section_bounds(wave_index, cave_ready)
    for index in waves.size():
        for enemy in waves[index]:
            if index < wave_index or cave_ready:
                enemy.queue_free()
            elif index == wave_index:
                _set_enemy_active(enemy, true)
    if restored:
        player.position = saved["position"].clamp(arena_bounds.position, arena_bounds.end)
        for pit in pits:
            if pit.grow(28.0).has_point(player.position):
                player.position = Vector2(pit.end.x + 45.0, 450)
        if cave_ready:
            # Old saves may be beyond the new trigger. Resume just before it
            # so the player can take the last step into the approach again.
            player.position.x = clampf(player.position.x, CAVE_CHECKPOINT_X, CAVE_TRIGGER_X - 24.0)
    player.last_safe_position = player.position
    player.get_node("Camera2D").reset_smoothing()
    road_open = cave_ready
    _save_checkpoint(checkpoint_id, "Checkpoint retomado" if restored else "Checkpoint salvo")

func _process(delta: float) -> void:
    _update_hud()
    if finished or cave_entering or player.hp <= 0:
        return
    tutorial.advance(delta)
    if not _section_is_clear():
        return
    road_open = true
    if wave_index == 0:
        _set_section_bounds(0, true)
        if player.position.x >= SECOND_STAGE_GATE and _has_landed():
            _start_section(1)
    elif wave_index == 1:
        _set_section_bounds(1, true)
        if player.position.x >= THIRD_STAGE_GATE and _has_landed():
            _start_section(2)
    else:
        cave_ready = true
        if player.position.x >= CAVE_CHECKPOINT_X and checkpoint_id != "caverna" and _has_landed():
            _save_checkpoint("caverna")
        var on_path: bool = player.position.y >= arena_bounds.position.y and player.position.y <= arena_bounds.end.y
        if player.position.x >= CAVE_TRIGGER_X and on_path and _has_landed():
            _enter_cave()

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
    section_label.name = "ForestRoute"
    section_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    section_label.add_theme_font_size_override("font_size", 21)
    section_label.add_theme_color_override("font_color", Color("e9dfb8"))
    section_label.add_theme_color_override("font_shadow_color", Color(0.01, 0.025, 0.02, 0.95))
    section_label.add_theme_constant_override("shadow_offset_x", 1)
    section_label.add_theme_constant_override("shadow_offset_y", 2)
    $HUD.add_child(section_label)
    section_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    section_label.offset_left = -185
    section_label.offset_right = 185
    section_label.offset_top = 25
    section_label.offset_bottom = 87

func _update_hud() -> void:
    super._update_hud()
    $HUD/BossHealth.hide()
    if section_label == null:
        return
    var objective := "Limpe o caminho"
    if road_open:
        objective = "Siga pela floresta"
    if wave_index == 0 and road_open:
        objective = "Salte o desfiladeiro"
    elif cave_ready:
        objective = "Entre na caverna"
    section_label.text = "FLORESTA DA CUCA  •  %d / 3\n%s" % [wave_index + 1, objective]

func _enter_cave() -> void:
    if cave_entering or not cave_ready or player.hp <= 0:
        return
    cave_entering = true
    boss_intro_running = true
    $HUD.hide()
    player._end_dodge()
    player.control_locked = true
    player.velocity = Vector2.ZERO
    player.set_physics_process(false)
    player.facing = 1
    var visual := player.get_node("Sprite") as AnimatedSprite2D
    visual.set_process(false)
    visual.position = player.sprite_base_position
    visual.flip_h = false
    visual.play("walk")
    var original := player.get_node("Camera2D") as Camera2D
    original.force_update_scroll()
    cave_camera = Camera2D.new()
    add_child(cave_camera)
    cave_camera.global_position = original.get_screen_center_position()
    cave_camera.zoom = original.zoom
    cave_camera.make_current()
    var curtain := CanvasLayer.new()
    curtain.layer = 8
    add_child(curtain)
    cave_fade = ColorRect.new()
    cave_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    cave_fade.color = Color(0.015, 0.025, 0.018, 0.0)
    curtain.add_child(cave_fade)
    cave_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    cave_entry_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    # The cinematic begins as the cave first appears. Follow the dirt below
    # the boulders at walking speed, while opening the view toward the doorway.
    var approach := Curve2D.new()
    approach.add_point(player.global_position)
    for point: Vector2 in [Vector2(3930, 535), Vector2(4200, 530), Vector2(4255, 490)]:
        if point.x > player.position.x:
            approach.add_point(to_global(point))
    cave_approach_seconds = maxf(0.1, approach.get_baked_length() / CAVE_WALK_SPEED)
    cave_entry_tween.tween_method(_walk_cave_approach.bind(approach, cave_camera.global_position, original.zoom),
        0.0, 1.0, cave_approach_seconds).set_trans(Tween.TRANS_LINEAR)
    cave_entry_tween.tween_callback(func():
        if visual.sprite_frames.has_animation("walk_up"):
            visual.play("walk_up")
    )
    cave_entry_tween.tween_property(player, "global_position", CAVE_DOOR, 0.28)
    cave_entry_tween.parallel().tween_property(player, "modulate:a", 0.0, 0.28)
    cave_entry_tween.tween_property(cave_fade, "color:a", 1.0, 0.55)
    cave_entry_tween.parallel().tween_property(music, "volume_db", -34.0, 0.55)
    cave_entry_tween.parallel().tween_property(forest_ambience, "volume_db", -42.0, 0.55)
    cave_entry_tween.tween_callback(_finish_cave)

func _walk_cave_approach(progress: float, path: Curve2D, camera_start: Vector2, camera_zoom: Vector2) -> void:
    var distance := path.get_baked_length() * progress
    var point := path.sample_baked(distance)
    var direction := point - path.sample_baked(maxf(0.0, distance - 4.0))
    player.global_position = point
    var visual := player.sprite as AnimatedSprite2D
    var animation: StringName = &"walk"
    if absf(direction.y) > absf(direction.x):
        animation = &"walk_up" if direction.y < 0.0 else &"walk_down"
    if visual.sprite_frames.has_animation(animation) and visual.animation != animation:
        visual.play(animation)
    if absf(direction.x) > 0.01:
        player.facing = 1 if direction.x > 0.0 else -1
        visual.flip_h = direction.x < 0.0
    var framing := smoothstep(0.0, 1.0, progress)
    var destination := Vector2(to_global(CAVE_DOOR).x - 160.0, camera_start.y)
    cave_camera.global_position = camera_start.lerp(destination, framing)
    cave_camera.zoom = camera_zoom.lerp(camera_zoom * 1.035, framing)

func _finish_cave() -> void:
    finished = true
    Progress.complete_stage(stage_index)
    get_node("/root/SceneTransition").load_level(next_stage_path)
