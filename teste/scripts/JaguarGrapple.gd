extends Node

const FRAMES := preload("res://scripts/JaguarFrames.gd")
const GOAL := 12.0
const STRUGGLE_SECONDS := 8.0
const PRESS_INTERVAL := 0.075
const FAILURE_DAMAGE := 2
const ARRIVE_SECONDS := 0.45
const PUSH_SECONDS := 0.6
const RETURN_SECONDS := 0.5

var level: Node2D
var jaguar: CharacterBody2D
var player: CharacterBody2D
var camera: Camera2D
var original_camera: Camera2D
var prompt: Control
var pair: AnimatedSprite2D
var overlay: Control
var punch: AudioStreamPlayer
var phase := "arriving"
var phase_time := 0.0
var elapsed := 0.0
var clock := 0.0
var progress := 0.0
var goal := GOAL
var result := false
var presses := 0
var k_down := false
var since_press := 1.0
var impulse := 0.0
var press_kick := Vector2.ZERO
var press_roll := 0.0
var anchor := Vector2.ZERO
var close_center := Vector2.ZERO
var arrival_center := Vector2.ZERO
var normal_zoom := Vector2.ONE
var return_center := Vector2.ZERO
var return_zoom := Vector2.ONE
var frozen_enemies: Array[Dictionary] = []
var saved: Dictionary = {}
var cleaned := false

func start(forest: Node2D, animal: CharacterBody2D) -> void:
    level = forest
    jaguar = animal
    player = level.player
    saved = {"physics": player.is_physics_processing(), "control": player.control_locked,
        "sprite_process": player.sprite.is_processing(), "sprite_visible": player.sprite.visible,
        "sprite_position": player.sprite.position, "sprite_rotation": player.sprite.rotation,
        "shadow": player.shadow_opacity, "layer": player.collision_layer,
        "mask": player.collision_mask, "intro": level.boss_intro_running,
        "hud": level.get_node("HUD").visible}
    original_camera = level.get_viewport().get_camera_2d()
    original_camera.force_update_scroll()
    normal_zoom = original_camera.zoom
    arrival_center = original_camera.get_screen_center_position()
    anchor = player.global_position
    close_center = anchor + Vector2(0, -34)
    player._end_dodge()
    player.velocity = Vector2.ZERO
    player.jump_height = 0.0
    player.jump_speed = 0.0
    player.control_locked = true
    player.set_physics_process(false)
    player.sprite.set_process(false)
    player.sprite.hide()
    player.shadow_opacity = 0.0
    player.queue_redraw()
    player.collision_layer = 0
    player.collision_mask = 0
    level.boss_intro_running = true
    level.get_node("HUD").hide()
    for enemy in get_tree().get_nodes_in_group("enemy"):
        if enemy == jaguar or not level.is_ancestor_of(enemy):
            continue
        var bar := enemy.get_node_or_null("HealthBar") as ProgressBar
        frozen_enemies.append({"actor": enemy, "mode": enemy.process_mode,
            "bar": bar, "bar_visible": bar.visible if bar != null else false})
        if bar != null:
            bar.hide()
        enemy.process_mode = Node.PROCESS_MODE_DISABLED
    jaguar.get_node("Sprite").hide()
    jaguar.get_node("HealthBar").hide()
    pair = AnimatedSprite2D.new()
    pair.name = "JaguarNeckStruggle"
    pair.sprite_frames = FRAMES.build()
    pair.offset = FRAMES.grounded_offset(pair.sprite_frames)
    pair.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    pair.z_index = 12
    pair.flip_h = jaguar.direction > 0
    level.add_child(pair)
    pair.global_position = anchor
    pair.play("struggle")
    pair.pause()
    camera = Camera2D.new()
    camera.name = "JaguarStruggleCamera"
    add_child(camera)
    camera.global_position = arrival_center
    camera.zoom = normal_zoom
    camera.make_current()
    var ui := CanvasLayer.new()
    ui.layer = 6
    add_child(ui)
    overlay = Control.new()
    overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(overlay)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.draw.connect(_draw_pressure)
    prompt = preload("res://scripts/JaguarMashPrompt.gd").new()
    ui.add_child(prompt)
    punch = AudioStreamPlayer.new()
    punch.stream = preload("res://soundeffect/Feedback/hit.wav")
    punch.volume_db = -15.0
    add_child(punch)
    k_down = Input.is_key_pressed(KEY_K) or Input.is_physical_key_pressed(KEY_K)
    preload("res://scripts/CombatVFX.gd").spawn(player, "smoke", anchor, Vector2.RIGHT, Color("b9ae81"), 48)
    preload("res://scripts/CombatVFX.gd").spawn(player, "ring", anchor, Vector2.RIGHT, Color("dfd19b"), 42)

func _process(delta: float) -> void:
    if cleaned or not is_instance_valid(player) or not is_instance_valid(jaguar):
        abort()
        return
    if player.hp <= 0 or level.finished:
        abort()
        return
    clock += delta
    phase_time += delta
    since_press += delta
    impulse = maxf(0.0, impulse - delta * 5.0)
    prompt.position = Vector2((get_viewport().get_visible_rect().size.x - prompt.size.x) * 0.5,
        get_viewport().get_visible_rect().size.y - prompt.size.y - 32.0)
    match phase:
        "arriving":
            var blend := smoothstep(0.0, ARRIVE_SECONDS, phase_time)
            camera.global_position = arrival_center.lerp(close_center, blend)
            camera.zoom = normal_zoom.lerp(normal_zoom * 1.48, blend)
            pair.modulate.a = minf(1.0, phase_time / 0.12)
            if phase_time >= ARRIVE_SECONDS:
                phase = "struggle"
                phase_time = 0.0
                prompt.show()
        "struggle":
            elapsed += delta
            if since_press > 0.85:
                progress = maxf(0.0, progress - delta * 0.6)
            prompt.progress_ratio = progress / goal
            prompt.danger_ratio = elapsed / STRUGGLE_SECONDS
            var strain := 0.5 + 0.5 * sin(clock * 13.0)
            pair.global_position = anchor + Vector2(sin(clock * 17.0) * 1.3, strain * 1.6 - impulse * 2.0)
            pair.rotation = sin(clock * 11.0) * 0.012 + (progress / goal) * (-0.026 if pair.flip_h else 0.026)
            _shake_camera(1.0)
            if elapsed >= STRUGGLE_SECONDS:
                _begin_push(false)
        "pushing":
            var blend := smoothstep(0.0, PUSH_SECONDS, phase_time)
            pair.modulate.a = 1.0 - minf(1.0, blend * 2.4)
            player.sprite.position = player.sprite_base_position + Vector2(0, (1.0 - blend) * 12.0)
            player.sprite.rotation = (1.0 - blend) * (-0.12 if pair.flip_h else 0.12)
            _shake_camera(1.0 - blend)
            if phase_time >= PUSH_SECONDS:
                _begin_return()
        "return":
            var blend := smoothstep(0.0, RETURN_SECONDS, phase_time)
            camera.global_position = return_center.lerp(_gameplay_center(), blend)
            camera.zoom = return_zoom.lerp(normal_zoom, blend)
            camera.offset *= 1.0 - blend
            camera.rotation *= 1.0 - blend
            if phase_time >= RETURN_SECONDS:
                _complete()
    overlay.queue_redraw()

func _shake_camera(strength: float) -> void:
    var danger := clampf(elapsed / STRUGGLE_SECONDS, 0, 1)
    var amount := (1.1 + danger * 1.6) * strength
    # A distinct recoil starts on the input event, then settles between taps.
    var decay := exp(-since_press * 19.0)
    var recoil := press_kick * decay * cos(since_press * 62.0)
    camera.offset = Vector2(sin(clock * 39.0) + sin(clock * 67.0) * 0.42,
        cos(clock * 47.0) * 0.72 + sin(clock * 71.0) * 0.25) * amount + recoil * strength
    camera.rotation = (sin(clock * 29.0) * 0.004 + press_roll * decay) * strength
    camera.zoom = normal_zoom * (1.48 + (sin(clock * 8.0) * 0.005 + impulse * 0.012) * strength)

func _input(event: InputEvent) -> void:
    if cleaned or get_tree().paused or not event is InputEventKey:
        return
    if event.keycode != KEY_K and event.physical_keycode != KEY_K:
        return
    if not event.pressed:
        k_down = false
    elif not event.echo and not k_down:
        k_down = true
        if phase == "struggle" and since_press >= PRESS_INTERVAL:
            since_press = 0.0
            progress = minf(goal, progress + 1.0)
            presses += 1
            impulse = 1.0
            var direction := 1.0 if presses % 2 == 1 else -1.0
            press_kick = Vector2(direction * 5.2, -3.0)
            press_roll = direction * 0.006
            _shake_camera(1.0)
            prompt.progress_ratio = progress / goal
            prompt.flash_press()
            punch.pitch_scale = 0.88 + float(presses % 3) * 0.07
            punch.play()
            if progress >= goal:
                _begin_push(true)
    get_viewport().set_input_as_handled()

func _begin_push(won: bool) -> void:
    if phase != "struggle":
        return
    result = won
    phase = "pushing"
    phase_time = 0.0
    prompt.hide()
    player.sprite.show()
    player.sprite.play("attack" if won else "hurt")
    player.sprite.position = player.sprite_base_position + Vector2(0, 12)
    player.facing = -1 if pair.flip_h else 1
    player.sprite.flip_h = pair.flip_h
    jaguar.get_node("Sprite").show()
    jaguar.finish_grapple(won)
    preload("res://scripts/CombatVFX.gd").spawn(player, "smoke", anchor, Vector2.RIGHT, Color("c4b78a"), 55)
    preload("res://scripts/CombatVFX.gd").spawn(player, "ring", anchor, Vector2.RIGHT, Color("f1cf81"), 48)
    punch.volume_db = -7.0
    punch.play()

func _begin_return() -> void:
    phase = "return"
    phase_time = 0.0
    return_center = camera.global_position
    return_zoom = camera.zoom
    player.sprite.position = player.sprite_base_position
    player.sprite.rotation = 0.0
    player.sprite.play("idle")

func _gameplay_center() -> Vector2:
    var target := player.global_position + original_camera.position
    var half_view := get_viewport().get_visible_rect().size / (normal_zoom * 2.0)
    target.x = clampf(target.x, original_camera.limit_left + half_view.x, original_camera.limit_right - half_view.x)
    target.y = clampf(target.y, original_camera.limit_top + half_view.y, original_camera.limit_bottom - half_view.y)
    return target

func _complete() -> void:
    phase = "finished"
    _restore()
    if not result and is_instance_valid(player) and player.hp > 0:
        # Use normal damage and death feedback, after cinematic protection ends.
        player.damage_cooldown = 0.0
        player.take_damage(FAILURE_DAMAGE)
    queue_free()

func abort() -> void:
    if cleaned:
        return
    phase = "finished"
    if is_instance_valid(jaguar) and jaguar.hp > 0:
        jaguar.get_node("Sprite").show()
        jaguar.abort_grapple()
    _restore()
    queue_free()

func _restore() -> void:
    if cleaned:
        return
    cleaned = true
    for item in frozen_enemies:
        if is_instance_valid(item.actor):
            item.actor.process_mode = item.mode
        if is_instance_valid(item.bar):
            item.bar.visible = item.bar_visible
    if is_instance_valid(player) and not saved.is_empty():
        player.control_locked = saved.control
        player.set_physics_process(saved.physics and player.hp > 0)
        player.sprite.set_process(saved.sprite_process)
        player.sprite.visible = saved.sprite_visible
        player.sprite.position = player.sprite_base_position
        player.sprite.rotation = saved.sprite_rotation
        player.shadow_opacity = saved.shadow
        player.collision_layer = saved.layer
        player.collision_mask = saved.mask
        # The finishing tap cannot spill into a regular attack on this frame.
        player.attack_cooldown_timer = maxf(player.attack_cooldown_timer, 0.4)
        player.damage_cooldown = maxf(player.damage_cooldown, 0.45)
        player.queue_redraw()
    if is_instance_valid(level) and not saved.is_empty():
        level.boss_intro_running = saved.intro
        level.get_node("HUD").visible = saved.hud
        if level.active_jaguar_grapple == self:
            level.active_jaguar_grapple = null
    if is_instance_valid(original_camera) and original_camera.is_inside_tree():
        original_camera.make_current()
        original_camera.reset_smoothing()
        original_camera.force_update_scroll()
    if is_instance_valid(camera):
        camera.offset = Vector2.ZERO
        camera.rotation = 0.0
    if is_instance_valid(pair):
        pair.queue_free()

func _draw_pressure() -> void:
    if phase not in ["arriving", "struggle", "pushing"]:
        return
    var view := overlay.size
    var intensity := clampf(elapsed / STRUGGLE_SECONDS, 0.0, 1.0)
    var fade := minf(clock / ARRIVE_SECONDS, 1.0)
    if phase == "pushing":
        fade *= 1.0 - phase_time / PUSH_SECONDS
    var tint := Color(0.06, 0.10, 0.02).lerp(Color(0.24, 0.035, 0.015), intensity)
    for index in range(12):
        var inset := float(index) * 9.0
        var shade := Color(tint, (1.0 - float(index) / 12.0) * 0.10 * fade)
        overlay.draw_rect(Rect2(inset, 0, 9, view.y), shade)
        overlay.draw_rect(Rect2(view.x - inset - 9, 0, 9, view.y), shade)
        overlay.draw_rect(Rect2(0, inset, view.x, 9), shade)
        overlay.draw_rect(Rect2(0, view.y - inset - 9, view.x, 9), shade)
    for index in range(16):
        var angle := index * 2.399
        var direction := Vector2.from_angle(angle)
        var beat := fposmod(clock * 1.6 + index * 0.61, 1.0)
        var point := view * 0.5 + direction * view * (0.58 - beat * 0.08)
        overlay.draw_line(point, point - direction * (18.0 + beat * 28.0), Color(0.8, 0.76, 0.44, (1.0 - beat) * 0.16 * fade), 1.0, true)

func _exit_tree() -> void:
    _restore()
