extends Node

const FRAMES := preload("res://scripts/VitoriaFrames.gd")
const DROWNED_HOLD_SECONDS := 2.5
const OFFSCREEN_HIT_DELAY_SECONDS := 1.0
const HIT_SETTLE_SECONDS := 0.65
const RISE_SECONDS := 1.65
const TRANSFORM_SECONDS := 1.45
const STAND_SECONDS := 0.7
const SHARED_LEAF_SCALE := 1.22
const ROUTE_GROW_SECONDS := 1.25
const MYSTERY_LINE := "Ela pode dominar o canto das águas. Mas não toda a vida que existe nelas."
const LINES := [
    ["player", "O que aconteceu? Quem é você?"],
    ["vitoria", "Eu sou a Vitória-Régia. Derrotei a Iara e tirei você da água."],
    ["vitoria", "Eu sabia que ela estava tramando algo com a Cuca, então vim investigar. Vi você lutando contra ela... Muito corajoso, por sinal."],
    ["player", "Obrigado por me salvar. Mas qual é o plano delas?"],
    ["vitoria", "Elas querem ressuscitar o Corpo-Seco, um homem de tamanha maldade que foi rejeitado tanto pelo céu quanto pelo inferno."],
    ["vitoria", "Se a Cuca conseguir trazê-lo de volta, não sabemos até onde ela será capaz de ir. Precisamos impedir esse ritual."],
    ["player", "Então preciso encontrar a Cuca. Onde ela está?"],
    ["vitoria", "Além deste rio há uma floresta fechada. No fim da trilha, você encontrará a entrada da caverna dela."],
    ["vitoria", "A Cuca prepara suas poções nas profundezas da caverna. Siga os sinais do ritual e tome cuidado: ela não vai deixar você chegar perto sem lutar."],
    ["player", "Entendi. Vou chegar lá antes que ela termine o ritual. Obrigado, Vitória-Régia."],
    ["vitoria", "O rio está calmo outra vez. Minhas folhas vão ajudar você a atravessar. Vá... e que a floresta proteja seus passos."],
]

var fight: Node2D
var sequence: Tween
var camera: Camera2D
var heroine: AnimatedSprite2D
var dialogue: Control
var blackout: ColorRect
var bars: CanvasLayer
var punch: AudioStreamPlayer
var waiting := false
var dialogue_opened := 0
var line_index := -1
var phase := "drowning"
var strike_played := false
var rescue_glow: Node2D
var effect_clock := 0.0
var bloom_strength := 0.0
var birth_pose: Sprite2D
var character_height := 190.0
var leaf_width := 190.0
var leaf_surface := -40.0
var leaf_destination := Vector2.ZERO
var leaf_start := Vector2.ZERO
var leaf_start_scale := Vector2.ONE
var player_start := Vector2.ZERO
var player_standing_start := Vector2.ZERO
var birth_standing_start := Vector2.ZERO
var home_position := Vector2.ZERO
var camera_start := Vector2.ZERO
var camera_dialogue_focus := Vector2.ZERO
var gameplay_zoom := Vector2.ONE
var dialogue_zoom := Vector2.ONE
var rise_start_zoom := Vector2.ONE
var leaf_route: Array[Vector2] = []
var exit_leaves: Array[AnimatedSprite2D] = []
var route_bases: Array[Vector2] = []

func start(level: Node2D) -> void:
    fight = level
    fight._clear_seduction()
    fight.boss_intro_running = true
    fight.get_node("HUD").hide()
    fight.player._end_dodge()
    fight.player.control_locked = true
    fight.player.set_physics_process(false)
    fight.player.velocity = Vector2.ZERO
    fight.player.jump_height = 0.0
    fight.player.jump_speed = 0.0
    fight.player.sprite.set_process(false)
    fight.player.sprite.play("hurt")
    for enemy in fight.get_tree().get_nodes_in_group("enemy"):
        enemy.set_physics_process(false)
    fight.boss.get_node("Sprite").set_process(false)
    fight.boss.get_node("Sprite").play("attack_loop")
    fight.music.volume_db = fight.original_music_volume - 10.0
    var original_camera := fight.get_viewport().get_camera_2d()
    original_camera.force_update_scroll()
    camera = Camera2D.new()
    camera.name = "RescueCamera"
    camera.zoom = original_camera.zoom
    # The dialogue needs vertical room that the combat camera's 180..580
    # limits cannot provide when zooming out. Only this camera is expanded.
    camera.limit_top = -200
    camera.limit_bottom = 1000
    add_child(camera)
    camera.global_position = original_camera.get_screen_center_position()
    camera.make_current()
    gameplay_zoom = fight.normal_camera_zoom
    dialogue_zoom = gameplay_zoom * 0.78
    bars = preload("res://scripts/BossEntrance.gd").new()
    bars.cool_theme = true
    add_child(bars)
    var ui := CanvasLayer.new()
    ui.layer = 5
    add_child(ui)
    blackout = ColorRect.new()
    blackout.color = Color(0, 0, 0, 0)
    blackout.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(blackout)
    blackout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dialogue = preload("res://scripts/DialogueBox.gd").new()
    ui.add_child(dialogue)
    dialogue.completed.connect(_on_dialogue_completed)
    punch = AudioStreamPlayer.new()
    punch.name = "RescuePunch"
    punch.stream = preload("res://soundeffect/Feedback/hit.wav")
    punch.volume_db = -5.0
    add_child(punch)
    heroine = AnimatedSprite2D.new()
    heroine.name = "VitoriaRegiaRescuer"
    heroine.sprite_frames = fight.vitoria_leaf.sprite_frames
    heroine.offset = FRAMES.grounded_offset(heroine.sprite_frames)
    heroine.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    heroine.position = fight.vitoria_leaf.position
    heroine.z_index = 5
    heroine.modulate.a = 0.0
    fight.add_child(heroine)
    character_height = FRAMES.visual_height(heroine.sprite_frames)
    leaf_width = FRAMES.leaf_width(heroine.sprite_frames)
    leaf_surface = FRAMES.leaf_surface_offset(heroine.sprite_frames)
    player_start = fight.player.position
    leaf_destination = player_start + Vector2(32, 12)
    # Keep the full shared leaf above the large dialogue box, with Iara on
    # the left bank and room for the crossing on the right.
    var view := get_viewport().get_visible_rect().size
    var leaf_bottom_line: float = view.y - dialogue.BOX_HEIGHT - dialogue.BOTTOM_MARGIN - 20.0
    camera_dialogue_focus = _focus(Vector2(leaf_destination.x - 105.0,
        leaf_destination.y - (leaf_bottom_line - view.y * 0.5) / dialogue_zoom.y), dialogue_zoom)
    rescue_glow = Node2D.new()
    rescue_glow.z_index = 3
    fight.add_child(rescue_glow)
    rescue_glow.draw.connect(_draw_rescue_glow)
    sequence = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    _sink(0.9)
    sequence.tween_property(camera, "global_position", _focus(player_start + Vector2(0, -45), camera.zoom), 0.6)
    sequence.parallel().tween_property(blackout, "color:a", 1.0, DROWNED_HOLD_SECONDS)
    sequence.tween_callback(_say_mystery)
    # The interval starts only after the entire mystery speech is completed.
    sequence.tween_interval(OFFSCREEN_HIT_DELAY_SECONDS)
    sequence.tween_callback(_offscreen_hit)
    sequence.tween_method(_collapse_iara, 0.0, 1.0, HIT_SETTLE_SECONDS).set_trans(Tween.TRANS_LINEAR)
    sequence.tween_callback(_raise_leaf)
    sequence.tween_method(_rise, 0.0, 1.0, RISE_SECONDS)
    sequence.tween_callback(_reveal)
    sequence.tween_method(_transform, 0.0, 1.0, TRANSFORM_SECONDS).set_trans(Tween.TRANS_LINEAR)
    sequence.tween_callback(_stand)
    sequence.tween_method(_settle_birth, 0.0, 1.0, STAND_SECONDS)
    sequence.tween_interval(0.35)
    sequence.tween_callback(_begin_conversation)
    sequence.tween_callback(_prepare_crossing)
    sequence.tween_method(_grow_crossing, 0.0, 1.0, ROUTE_GROW_SECONDS).set_trans(Tween.TRANS_LINEAR)
    sequence.tween_interval(0.45)
    sequence.tween_callback(_finish)

func _focus(point: Vector2, zoom: Vector2) -> Vector2:
    var half_view := get_viewport().get_visible_rect().size.y / (zoom.y * 2.0)
    point.y = clampf(point.y, camera.limit_top + half_view, camera.limit_bottom - half_view)
    return point

func _pose(animation: StringName, progress: float) -> void:
    if heroine.animation != animation:
        heroine.play(animation)
    heroine.pause()
    var count := heroine.sprite_frames.get_frame_count(animation)
    heroine.set_frame_and_progress(mini(count - 1, int(clampf(progress, 0.0, 1.0) * count)), 0.0)

func _say_mystery() -> void:
    phase = "mystery_dialogue"
    dialogue.portrait.modulate = Color(0.08, 0.08, 0.08, 1.0)
    dialogue.begin("vitoria", "", [MYSTERY_LINE])
    _wait_for_dialogue()

func _offscreen_hit() -> void:
    phase = "offscreen_hit"
    strike_played = true
    blackout.color.a = 1.0
    punch.play()
    fight.sound_effects.play_effect("hit")
    fight.chant.stop()
    fight.boss.hp = 0
    fight.state = fight.State.DEFEATED
    fight.boss.collision_layer = 0
    fight.boss.collision_mask = 0
    fight.boss.get_node("HurtArea").collision_layer = 0
    var visual := fight.boss.get_node("Sprite") as AnimatedSprite2D
    visual.play("fall")
    visual.pause()
    if visual.material is ShaderMaterial:
        visual.material.set_shader_parameter("flash", 0.0)

func _collapse_iara(progress: float) -> void:
    var visual := fight.boss.get_node("Sprite") as AnimatedSprite2D
    var count := visual.sprite_frames.get_frame_count("fall")
    visual.set_frame_and_progress(mini(count - 1, int(progress * count)), 0.0)

func _raise_leaf() -> void:
    phase = "rescue"
    # Extend the water side of the supplied river painting. Repeating the
    # complete image would put a new dry bank underneath the departure leaves.
    var river_paint := ShaderMaterial.new()
    river_paint.shader = preload("res://shaders/rescue_river.gdshader")
    fight.boss_ground.material = river_paint
    fight.boss_ground.region_rect.size.x = maxf(fight.boss_ground.region_rect.size.x,
        (leaf_destination.x + 1400.0 - fight.boss_ground.position.x) / fight.boss_ground.scale.x)
    # Reveal the aftermath on the bank, instead of fading Iara away.
    var bounds: Rect2 = fight.boss.combat_bounds
    fight.boss.position = Vector2(fight.WATER_EDGE - 18.0 - bounds.end.x,
        leaf_destination.y + leaf_surface * SHARED_LEAF_SCALE - bounds.end.y - 4.0)
    fight.boss.show()
    fight.boss.get_node("Sprite").modulate = Color(0.78, 0.84, 0.91, 1.0)
    leaf_start = fight.vitoria_leaf.position
    leaf_start_scale = fight.vitoria_leaf.scale
    camera_start = camera.global_position
    rise_start_zoom = camera.zoom
    fight.player.z_index = 4
    fight.player.sprite.position = fight.player.sprite_base_position
    fight.player.sprite.modulate = Color.WHITE
    fight.player.facing = -1
    fight.player.sprite.flip_h = true

func _rise(progress: float) -> void:
    fight.vitoria_leaf.position = leaf_start.lerp(leaf_destination, progress)
    fight.vitoria_leaf.scale = leaf_start_scale.lerp(Vector2.ONE, progress)
    fight.vitoria_leaf.modulate.a = 1.0
    fight.player.position = player_start.lerp(_leaf_seat(1.0, 1.0, true), progress)
    _sink(0.9 * (1.0 - progress))
    blackout.color.a = 1.0 - smoothstep(0.0, 0.82, progress)
    bloom_strength = progress * 0.75
    fight.music.volume_db = fight.original_music_volume - lerpf(10.0, 4.0, progress)
    camera.zoom = rise_start_zoom.lerp(dialogue_zoom, progress)
    camera.global_position = _focus(camera_start.lerp(camera_dialogue_focus, progress), camera.zoom)

func _reveal() -> void:
    phase = "reveal"
    fight._restore_water_visual()
    fight.veil.color.a = 0.0
    fight.low_pass.cutoff_hz = 20000.0
    fight.player.sprite.play("idle")
    heroine.position = leaf_destination
    heroine.scale = Vector2.ONE * FRAMES.emergence_start_scale(heroine.sprite_frames)
    heroine.flip_h = true
    heroine.modulate.a = 1.0
    _pose("transform", 0.0)
    # The transformation includes its own leaf; draw it exactly once.
    fight.vitoria_leaf.hide()

func _transform(progress: float) -> void:
    _pose("transform", progress)
    heroine.scale = Vector2.ONE * lerpf(FRAMES.emergence_start_scale(heroine.sprite_frames), 1.0, smoothstep(0.0, 0.72, progress))
    heroine.position = leaf_destination + Vector2(0, leaf_surface * smoothstep(0.35, 1.0, progress))
    # The new final drawings contain water around her feet, not a platform.
    # Bring the bare leaf in before the flower has completely disappeared.
    fight.vitoria_leaf.play("leaf")
    fight.vitoria_leaf.visible = progress > 0.4
    fight.vitoria_leaf.modulate.a = smoothstep(0.4, 0.82, progress)
    bloom_strength = 0.75 + sin(progress * PI) * 0.25

func _stand() -> void:
    phase = "stand"
    birth_pose = Sprite2D.new()
    birth_pose.texture = heroine.sprite_frames.get_frame_texture("transform", heroine.sprite_frames.get_frame_count("transform") - 1)
    birth_pose.offset = heroine.offset
    birth_pose.flip_h = heroine.flip_h
    birth_pose.texture_filter = heroine.texture_filter
    birth_pose.position = heroine.position
    birth_pose.z_index = heroine.z_index
    fight.add_child(birth_pose)
    birth_standing_start = heroine.position
    player_standing_start = fight.player.position
    home_position = _leaf_seat(-1.0)
    heroine.position = birth_standing_start
    heroine.scale = Vector2.ONE
    heroine.modulate.a = 0.0
    _pose("idle", 0.0)
    fight.vitoria_leaf.play("leaf")
    fight.vitoria_leaf.show()

func _settle_birth(progress: float) -> void:
    birth_pose.modulate.a = 1.0 - smoothstep(0.0, 0.8, progress)
    heroine.modulate.a = smoothstep(0.0, 0.7, progress)
    fight.vitoria_leaf.modulate.a = 1.0
    fight.vitoria_leaf.scale = Vector2.ONE * lerpf(1.0, SHARED_LEAF_SCALE, progress)
    heroine.position = birth_standing_start.lerp(home_position, progress)
    birth_pose.position = heroine.position
    fight.player.position = player_standing_start.lerp(_leaf_seat(1.0, SHARED_LEAF_SCALE, true), progress)
    _pose("idle", progress)
    bloom_strength = lerpf(0.75, 0.28, progress)

func _leaf_seat(side: float, platform_scale: float = SHARED_LEAF_SCALE, for_player: bool = false) -> Vector2:
    var seat := leaf_destination + Vector2(side * leaf_width * platform_scale * 0.22, leaf_surface * platform_scale)
    if for_player:
        seat.y -= fight.player.combat_bounds.end.y
    return seat

func _begin_conversation() -> void:
    phase = "conversation"
    if is_instance_valid(birth_pose):
        birth_pose.queue_free()
    heroine.flip_h = true
    heroine.play("idle")
    line_index = 0
    dialogue.portrait.modulate = Color.WHITE
    _show_line()
    _wait_for_dialogue()

func _show_line() -> void:
    dialogue.begin(LINES[line_index][0], "", [LINES[line_index][1]])
    dialogue_opened = Time.get_ticks_msec()

func _wait_for_dialogue() -> void:
    waiting = true
    dialogue_opened = Time.get_ticks_msec()
    sequence.pause()

func _on_dialogue_completed() -> void:
    if phase == "conversation":
        line_index += 1
        if line_index < LINES.size():
            _show_line()
            return
    elif phase == "mystery_dialogue":
        phase = "silent_wait"
    waiting = false
    sequence.play()

func _prepare_crossing() -> void:
    phase = "farewell"
    fight.vitoria_leaf.position = leaf_destination
    heroine.position = home_position
    fight.player.position = _leaf_seat(1.0, SHARED_LEAF_SCALE, true)
    fight.player.facing = 1
    fight.player.sprite.flip_h = false
    var spacing := clampf(leaf_width * 0.85, 125.0, 150.0)
    for index in range(6):
        var leaf := AnimatedSprite2D.new()
        leaf.name = "CrossingLeaf%d" % (index + 1)
        leaf.sprite_frames = heroine.sprite_frames
        leaf.offset = heroine.offset
        leaf.texture_filter = heroine.texture_filter
        leaf.play("leaf")
        leaf.z_index = 2
        var size_factor := 0.88 + sin(index * 1.7) * 0.06
        leaf.scale = Vector2.ONE * size_factor
        var surface_y := leaf_destination.y + leaf_surface * SHARED_LEAF_SCALE + sin(index * 1.8) * 7.0
        var destination := Vector2(leaf_destination.x + spacing * (index + 1), surface_y - leaf_surface * size_factor)
        leaf.position = destination + Vector2(0, 18)
        leaf.modulate.a = 0.0
        fight.add_child(leaf)
        exit_leaves.append(leaf)
        route_bases.append(destination)
        leaf_route.append(fight.to_global(Vector2(destination.x, surface_y - fight.player.combat_bounds.end.y)))

func _grow_crossing(progress: float) -> void:
    for index in range(exit_leaves.size()):
        var reveal := smoothstep(index * 0.10, index * 0.10 + 0.48, progress)
        exit_leaves[index].modulate.a = reveal
        exit_leaves[index].position = route_bases[index] + Vector2(0, (1.0 - reveal) * 18.0)
    bloom_strength = lerpf(0.28, 0.14, progress)

func _process(delta: float) -> void:
    effect_clock += delta
    if is_instance_valid(rescue_glow):
        rescue_glow.position = fight.vitoria_leaf.position
        rescue_glow.queue_redraw()
    if phase == "conversation":
        var bob := sin(effect_clock * 1.65) * 1.0
        fight.vitoria_leaf.position = leaf_destination + Vector2(0, bob)
        heroine.position = home_position + Vector2(0, bob)
        fight.player.position = _leaf_seat(1.0, SHARED_LEAF_SCALE, true) + Vector2(0, bob)

func _draw_rescue_glow() -> void:
    if bloom_strength <= 0.0:
        return
    rescue_glow.draw_set_transform(Vector2(0, leaf_surface * fight.vitoria_leaf.scale.y), 0.0, Vector2(1.0, 0.3))
    for index in range(3):
        var progress := fposmod(effect_clock * 0.3 + index / 3.0, 1.0)
        var glow := Color(0.58, 1.0, 0.78, bloom_strength * (1.0 - progress) * 0.15)
        rescue_glow.draw_arc(Vector2.ZERO, leaf_width * 0.32 + progress * 32.0, 0.0, TAU, 48, glow, 1.0, true)
    rescue_glow.draw_set_transform(Vector2.ZERO)
    for index in range(16):
        var progress := fposmod(effect_clock * 0.4 + index * 0.618, 1.0)
        var point := Vector2(sin(index * 2.4 + effect_clock) * leaf_width * 0.4, leaf_surface - progress * 70.0)
        rescue_glow.draw_circle(point, 1.2, Color(0.9, 1.0, 0.65, sin(progress * PI) * bloom_strength * 0.4))
    for index in range(exit_leaves.size()):
        var center := exit_leaves[index].position - rescue_glow.position + Vector2(0, leaf_surface * exit_leaves[index].scale.y)
        rescue_glow.draw_set_transform(center, 0.0, Vector2(1.0, 0.22))
        var ripple := fposmod(effect_clock * 0.45 + index * 0.21, 1.0)
        rescue_glow.draw_arc(Vector2.ZERO, leaf_width * 0.35 + ripple * 16.0, 0.0, TAU, 36,
            Color(0.55, 0.85, 0.75, (1.0 - ripple) * exit_leaves[index].modulate.a * 0.16), 1.0, true)
    rescue_glow.draw_set_transform(Vector2.ZERO)

func _unhandled_input(event: InputEvent) -> void:
    if waiting and Time.get_ticks_msec() - dialogue_opened > 250 and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_SPACE]:
        dialogue.advance()
        get_viewport().set_input_as_handled()

func _sink(depth: float) -> void:
    fight._set_submersion(depth)
    fight.veil.color.a = depth * 0.48
    fight.low_pass.cutoff_hz = lerpf(20000.0, 300.0, depth)

func _finish() -> void:
    phase = "finished"
    fight.veil.color.a = 0.0
    camera.offset = Vector2.ZERO
    camera.make_current()
    fight.boss_intro_running = false
    bars.dismiss(0.55)
    # Keep this camera alive through the victory title and departure jumps.
    fight.iara_defeated(camera, leaf_route)

func _exit_tree() -> void:
    if is_instance_valid(rescue_glow):
        rescue_glow.queue_free()
    if is_instance_valid(birth_pose):
        birth_pose.queue_free()
