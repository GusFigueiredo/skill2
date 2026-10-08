extends Control

enum Step { WALK, DODGE, JUMP, ATTACK, COMPLETE }

var step: Step = Step.WALK
var level: Node2D
var heading: Label
var message: Label
var progress: Label
var card: PanelContainer
var reward_timer := 0.0
var walked := 0.0
var previous_position := Vector2.ZERO
var combat_dodge_done := false
var combat_hit_done := false
var lesson_enemy: CharacterBody2D
var introducing_enemy := false
var arrival_tween: Tween
var cinematic_camera: Camera2D
var original_camera: Camera2D
var original_camera_center := Vector2.ZERO
var waiting_for_dodge := false
var dodge_zoom_ready := false
var dodge_camera_tween: Tween

const WALK_DISTANCE := 250.0
const COMPLETION_DURATION := 2.5

func setup(game: Node2D) -> void:
	level = game
	previous_position = level.player.position
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	card = PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.custom_minimum_size = Vector2(470, 150)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("172b29")
	style.border_color = Color("dfbd72")
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	style.shadow_size = 8
	style.shadow_color = Color(0, 0, 0, 0.35)
	card.add_theme_stylebox_override("panel", style)
	add_child(card)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 7)
	card.add_child(box)
	heading = _label(box, 24, Color("ffe3a1"))
	message = _label(box, 20, Color("f4eddb"))
	message.custom_minimum_size.x = 426
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progress = _label(box, 16, Color("8bdac4"))
	progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_show_step()

func _label(box: VBoxContainer, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	box.add_child(label)
	return label

func _process(delta: float) -> void:
	if not is_instance_valid(level):
		return
	visible = not introducing_enemy and step != Step.COMPLETE and level.player.hp > 0 and not level.finished
	var viewport_size := get_viewport_rect().size
	var hero = level.player
	var head := Vector2(hero.combat_bounds.get_center().x, hero.combat_bounds.position.y - hero.jump_height)
	var player_point: Vector2 = hero.get_global_transform_with_canvas() * head
	# Anchor the balloon above the visible head, including camera zoom and jumps.
	position = Vector2(clampf(player_point.x - card.size.x * 0.5, 16.0, maxf(16.0, viewport_size.x - card.size.x - 16.0)), maxf(16.0, player_point.y - card.size.y - 29.0))
	queue_redraw()

func _draw() -> void:
	if card == null:
		return
	var tip_x := card.size.x * 0.5
	if is_instance_valid(level):
		tip_x = clampf(level.player.get_global_transform_with_canvas().origin.x - position.x, 24.0, card.size.x - 24.0)
	var base_y := card.size.y
	draw_colored_polygon(PackedVector2Array([Vector2(tip_x - 13, base_y - 1), Vector2(tip_x, base_y + 17), Vector2(tip_x + 13, base_y - 1)]), Color("172b29"))
	draw_polyline(PackedVector2Array([Vector2(tip_x - 13, base_y), Vector2(tip_x, base_y + 17), Vector2(tip_x + 13, base_y)]), Color("dfbd72"), 2.0, true)

func advance(delta: float) -> void:
	if introducing_enemy or waiting_for_dodge:
		return
	var hero = level.player
	var distance: float = previous_position.distance_to(hero.position)
	previous_position = hero.position
	if reward_timer > 0.0:
		reward_timer = maxf(0.0, reward_timer - delta)
		if reward_timer <= 0.0:
			step = (step + 1) as Step
			hero.has_dodged = false
			hero.has_jumped = false
			if step == Step.ATTACK:
				_start_enemy_arrival()
				return
			_show_step()
		return
	match step:
		Step.WALK:
			if not hero.is_dodging and not hero._is_airborne():
				walked += distance
			progress.text = "Caminhe pela arena: %d / 250 pixels" % mini(250, int(walked))
			if walked >= WALK_DISTANCE:
				_complete_action("Muito bem! Agora vamos aprender a esquivar.")
		Step.DODGE:
			if hero.has_dodged and not hero.is_dodging:
				_complete_action("Boa esquiva! Vamos experimentar o pulo.")
		Step.JUMP:
			if hero.has_jumped and not hero._is_airborne() and not hero.is_falling and hero.position.x > 1166.0:
				_complete_action("Boa! Você está pronto para enfrentar um inimigo.")
		Step.ATTACK:
			var enemy = level.waves[0][0]
			combat_hit_done = combat_hit_done or not is_instance_valid(enemy) or enemy.hp < enemy.max_hp
			if combat_hit_done and combat_dodge_done:
				_complete_action("Acertou! Use o que aprendeu para vencer os inimigos.")
		Step.COMPLETE:
			hide()

func _complete_action(text: String) -> void:
	message.text = text
	progress.text = "✓ Etapa concluída!"
	reward_timer = COMPLETION_DURATION

func intercept_attack(enemy: CharacterBody2D) -> bool:
	if step != Step.ATTACK or introducing_enemy or combat_dodge_done or enemy != lesson_enemy:
		return false
	var hero = level.player
	# Wait for an available roll instead of freezing an airborne player.
	if not hero.can_dodge or hero.is_dodging or hero._is_airborne():
		return true
	waiting_for_dodge = true
	dodge_zoom_ready = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	hero.velocity = Vector2.ZERO
	hero.facing = 1 if enemy.position.x > hero.position.x else -1
	hero.sprite.flip_h = hero.facing < 0
	hero.sprite.play("idle")
	hero.sprite.set_frame_and_progress(0, 0.0)
	enemy.get_node("Sprite").play("attack")
	enemy.queue_redraw()
	heading.text = "Pausa do tutorial: esquive do ataque!"
	message.text = "Quando aparecer a caixa amarela, o inimigo está preparando um golpe. Use Shift para dar um dodge e desviar do ataque!"
	progress.text = "Shift: esquivar e continuar o combate"
	original_camera = hero.get_node("Camera2D")
	original_camera_center = original_camera.get_screen_center_position()
	cinematic_camera = Camera2D.new()
	cinematic_camera.process_mode = Node.PROCESS_MODE_ALWAYS
	level.add_child(cinematic_camera)
	cinematic_camera.global_position = original_camera_center
	cinematic_camera.zoom = original_camera.zoom
	cinematic_camera.make_current()
	level.music.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	dodge_camera_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	dodge_camera_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	dodge_camera_tween.tween_property(cinematic_camera, "global_position", (hero.global_position + enemy.global_position) * 0.5 + Vector2(0, -60), 0.6)
	dodge_camera_tween.tween_property(cinematic_camera, "zoom", original_camera.zoom * 1.3, 0.6)
	dodge_camera_tween.chain().tween_callback(func(): dodge_zoom_ready = true)
	return true

func _input(event: InputEvent) -> void:
	if not waiting_for_dodge or not event is InputEventKey or not event.pressed or event.echo:
		return
	get_viewport().set_input_as_handled()
	if not dodge_zoom_ready or (event.keycode != KEY_SHIFT and event.physical_keycode != KEY_SHIFT):
		return
	var hero = level.player
	var movement := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	movement += Vector2(float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)), float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)))
	hero._start_dodge(movement.x)
	if not hero.is_dodging:
		return
	hero.dodge_vector = movement.normalized() if movement.length_squared() > 0.0 else Vector2(hero.facing, 0)
	hero.dodge_key_was_pressed = true
	waiting_for_dodge = false
	get_tree().paused = false
	level.music.process_mode = Node.PROCESS_MODE_INHERIT
	process_mode = Node.PROCESS_MODE_INHERIT
	if is_instance_valid(lesson_enemy):
		lesson_enemy._release_attack()
	_restore_dodge_camera()

func _restore_dodge_camera() -> void:
	var camera := cinematic_camera
	dodge_camera_tween = create_tween().set_parallel(true)
	dodge_camera_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	dodge_camera_tween.tween_property(camera, "zoom", original_camera.zoom, 0.35)
	dodge_camera_tween.tween_property(camera, "global_position", original_camera_center, 0.35)
	dodge_camera_tween.chain().tween_callback(func():
		original_camera.make_current()
		camera.queue_free()
	)

func record_combat_dodge(enemy: CharacterBody2D) -> void:
	if step != Step.ATTACK or enemy != lesson_enemy or combat_dodge_done:
		return
	combat_dodge_done = true
	heading.text = "Boa esquiva!"
	message.text = "Sua rolada evitou o golpe! Ataque com K e use Shift quando o inimigo anunciar outro ataque."
	progress.text = "Esquiva em combate concluída"

func _enemy_spawn_position() -> Vector2:
	var hero_position: Vector2 = level.player.position
	var bounds: Rect2 = level.arena_bounds
	var side := 1.0 if hero_position.x + 260.0 <= bounds.end.x else -1.0
	return (hero_position + Vector2(side * 260.0, 0)).clamp(bounds.position, bounds.end)

func _start_enemy_arrival() -> void:
	introducing_enemy = true
	hide()
	lesson_enemy = level.waves[0][0]
	lesson_enemy.position = _enemy_spawn_position()
	# Show the entrance before enabling AI, solid collisions or damage.
	level._set_enemy_active(lesson_enemy, false)
	lesson_enemy.visible = true
	lesson_enemy.get_node("HealthBar").hide()
	var visual := lesson_enemy.get_node("Sprite") as AnimatedSprite2D
	visual.set_process(false)
	visual.flip_h = lesson_enemy.position.x > level.player.position.x
	visual.modulate.a = 0.0
	visual.animation = "death"
	visual.frame = visual.sprite_frames.get_frame_count("death") - 1
	visual.pause()
	original_camera = level.player.get_node("Camera2D")
	original_camera_center = original_camera.get_screen_center_position()
	cinematic_camera = Camera2D.new()
	level.add_child(cinematic_camera)
	cinematic_camera.global_position = original_camera_center
	cinematic_camera.zoom = original_camera.zoom
	cinematic_camera.make_current()
	arrival_tween = create_tween()
	arrival_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	arrival_tween.tween_property(cinematic_camera, "global_position", lesson_enemy.global_position + Vector2(0, lesson_enemy.combat_bounds.get_center().y), 0.55)
	arrival_tween.parallel().tween_property(cinematic_camera, "zoom", original_camera.zoom * 1.35, 0.55)
	arrival_tween.tween_property(visual, "modulate:a", 1.0, 0.2)
	var last_frame := visual.sprite_frames.get_frame_count("death") - 1
	var appearance_duration := maxf(0.6, float(last_frame + 1) / visual.sprite_frames.get_animation_speed("death"))
	# Drive the death frames backwards while the visual state machine is suspended.
	arrival_tween.parallel().tween_method(func(value: float): visual.frame = clampi(roundi(value), 0, last_frame), float(last_frame), 0.0, appearance_duration)
	arrival_tween.tween_callback(func(): visual.play("idle"))
	arrival_tween.tween_interval(0.25)
	arrival_tween.tween_callback(_zoom_out_arrival)

func _zoom_out_arrival() -> void:
	if not is_instance_valid(level) or not is_instance_valid(cinematic_camera):
		return
	arrival_tween = create_tween().set_parallel(true)
	arrival_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	arrival_tween.tween_property(cinematic_camera, "zoom", original_camera.zoom, 0.6)
	arrival_tween.tween_property(cinematic_camera, "global_position", original_camera.global_position, 0.6)
	arrival_tween.chain().tween_callback(_finish_enemy_arrival)

func _finish_enemy_arrival() -> void:
	original_camera.make_current()
	cinematic_camera.queue_free()
	introducing_enemy = false
	if level.player.hp <= 0 or level.finished:
		hide()
		return
	var visual := lesson_enemy.get_node("Sprite") as AnimatedSprite2D
	visual.modulate.a = 1.0
	visual.speed_scale = 1.0
	visual.play("idle")
	visual.set_process(true)
	lesson_enemy.get_node("HealthBar").show()
	lesson_enemy.attack_cooldown_timer = 1.0
	lesson_enemy.spawn_started = true
	lesson_enemy.spawn_finished = true
	level._set_enemy_active(lesson_enemy, true)
	previous_position = level.player.position
	_show_step()
	show()

func _show_step() -> void:
	progress.text = "Pratique para continuar"
	match step:
		Step.WALK:
			heading.text = "1 / 4 • Andar"
			message.text = "Use WASD ou as setas para andar pela arena. Experimente mover-se para os lados e para cima ou baixo."
		Step.DODGE:
			heading.text = "2 / 4 • Esquivar"
			message.text = "Pressione Shift para rolar. Segure uma direção para escolher para onde ir. Durante a rolada, você evita golpes!"
		Step.JUMP:
			heading.text = "3 / 4 • Pular"
			message.text = "Avance para a direita e use Espa\u00e7o para saltar sobre o buraco e chegar na segunda \u00e1rea."
		Step.ATTACK:
			heading.text = "4 / 4 • Combate"
			message.text = "Use K para atacar na direção do movimento. A caixa amarela anuncia o golpe inimigo: use Shift para desviar durante o ataque!"
		Step.COMPLETE:
			hide()
			return
