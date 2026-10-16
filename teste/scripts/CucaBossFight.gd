extends Node2D

signal defeated
signal phase_changed(phase: int)
signal hint_changed(text: String)

enum State { INTRO, CHANNELING, CASTING, RECOVERY, STAGGERED, DEFEATED }

const ACTOR := preload("res://scripts/CucaBossActor.gd")
const FRAMES := preload("res://scripts/CucaFrames.gd")
const SPELL := preload("res://scripts/CucaSpell.gd")
const HAZARD := preload("res://scripts/CucaHazard.gd")
const STALACTITE := preload("res://scripts/CaveStalactite.gd")
const VFX := preload("res://scripts/CombatVFX.gd")
const ENTRANCE := preload("res://scripts/BossEntrance.gd")
const CAULDRON_POSITION := Vector2(4770, 405)
const BOSS_START := Vector2(4830, 475)
const PHASE_PATTERNS := [
	["skull", "poison", "skull", "wave"],
	["skull", "poison", "wave", "stones", "skull", "poison_wave"],
	["skull", "poison_wave", "stones", "skull", "wave", "poison"],
]

var level: Node2D
var actor: Node2D
var cauldron: Sprite2D
var ritual_visual: AnimatedSprite2D
var state: State = State.INTRO
var state_timer := 0.0
var active := false
var phase := 0
var elapsed := 0.0
var action_index := 0
var current_attack := "skull"
var cast_released := false
var defeat_emitted := false
var intro_finished := false
var overload_flash := 0.0
var reflected_count := 0
var overload_count := 0
var projectiles: Array[Node2D] = []
var hazards: Array[Node2D] = []
var boss_stalactites: Array[Node2D] = []
var sounds := preload("res://scripts/SoundEffects.gd").new()
var motes: Array[Dictionary] = []
var mote_clock := 0.0
var relocated := false
var intro_player_start := Vector2.ZERO
var intro_camera_start := Vector2.ZERO
var intro_zoom_start := Vector2.ONE
var encounter_camera: Camera2D
var intro_revealed := false
var entrance_overlay: CanvasLayer
var entrance_dismissing := false
var shield_flash := 0.0
var shield_hint_cooldown := 0.0

func setup(cave: Node2D) -> void:
	level = cave

func _ready() -> void:
	name = "CucaBossFight"
	y_sort_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	actor = ACTOR.new()
	actor.controller = self
	actor.position = BOSS_START
	add_child(actor)
	cauldron = Sprite2D.new()
	cauldron.name = "RitualCauldron"
	cauldron.texture = FRAMES.cauldron_texture()
	cauldron.scale = Vector2.ONE * (113.0 / cauldron.texture.get_height())
	cauldron.position = CAULDRON_POSITION - Vector2(0, 56.5)
	add_child(cauldron)
	ritual_visual = AnimatedSprite2D.new()
	ritual_visual.name = "RitualCuca"
	ritual_visual.sprite_frames = FRAMES.ritual_frames(125.0)
	ritual_visual.position = CAULDRON_POSITION + FRAMES.grounded_offset(ritual_visual.sprite_frames)
	ritual_visual.hide()
	add_child(ritual_visual)
	add_child(sounds)
	sounds.setup({
		"cast": "res://soundeffect/Feedback/evade.wav",
		"counter": "res://soundeffect/Feedback/hit.wav",
		"overload": "res://soundeffect/Feedback/hit.wav",
		"wave": "res://soundeffect/Personagem/dodge.wav",
	}, {"cast": -8.0, "counter": -2.0, "overload": -1.0, "wave": -10.0})
	(sounds.players["cast"] as AudioStreamPlayer).pitch_scale = 0.6
	(sounds.players["counter"] as AudioStreamPlayer).pitch_scale = 1.55
	(sounds.players["overload"] as AudioStreamPlayer).pitch_scale = 0.5
	(sounds.players["wave"] as AudioStreamPlayer).pitch_scale = 0.65
	if level.player.has_signal("attack_performed"):
		level.player.connect("attack_performed", _on_player_attack)
	# Extract the shared K artwork during level loading, before a projectile
	# needs it in the middle of a counter window.
	var key_warmup := preload("res://scripts/JaguarMashPrompt.gd").new()
	add_child(key_warmup)
	key_warmup.queue_free()
	actor.hide()
	cauldron.hide()

func start_encounter() -> void:
	if active or actor.hp <= 0:
		return
	active = true
	actor.hide()
	cauldron.hide()
	ritual_visual.show()
	ritual_visual.play("mix")
	level.boss_intro_running = true
	level.get_node("HUD").hide()
	level.player.control_locked = true
	level.player.velocity = Vector2.ZERO
	level.player.get_node("Sprite").play("idle")
	intro_player_start = level.player.global_position
	encounter_camera = level.player.get_node("Camera2D") as Camera2D
	intro_camera_start = encounter_camera.get_screen_center_position()
	intro_zoom_start = encounter_camera.zoom
	encounter_camera.top_level = true
	encounter_camera.position_smoothing_enabled = false
	encounter_camera.limit_left = 0
	encounter_camera.limit_right = 5200
	encounter_camera.limit_top = 60
	encounter_camera.limit_bottom = 740
	encounter_camera.global_position = intro_camera_start
	entrance_overlay = ENTRANCE.new()
	entrance_overlay.cool_theme = true
	add_child(entrance_overlay)
	entrance_overlay.screen.modulate = Color(0.8, 1.0, 0.48)
	entrance_overlay.set_title("CUCA", "A BRUXA DO RITUAL")
	_set_state(State.INTRO)
	hint_changed.emit("A Cuca está preparando o ritual...")
	actor.play("idle")

func _physics_process(delta: float) -> void:
	if not active:
		return
	if not is_instance_valid(level) or level.player.hp <= 0 or level.finished:
		_clear_attacks()
		active = false
		return
	elapsed += delta
	state_timer += delta
	overload_flash = maxf(0.0, overload_flash - delta)
	shield_flash = maxf(0.0, shield_flash - delta)
	shield_hint_cooldown = maxf(0.0, shield_hint_cooldown - delta)
	_update_motes(delta)
	_update_facing()
	_clean_arrays()
	cauldron.modulate = Color(1.0 + overload_flash, 1.0 + overload_flash, 1.0 + overload_flash * 0.6)
	match state:
		State.INTRO:
			var travel := smoothstep(0.0, 1.5, state_timer)
			encounter_camera.global_position = intro_camera_start.lerp(Vector2(4605, 385), travel)
			encounter_camera.zoom = intro_zoom_start.lerp(Vector2.ONE * 1.4, travel)
			var previous_position: Vector2 = level.player.global_position
			level.player.global_position = intro_player_start.lerp(Vector2(4270, 460), smoothstep(0.0, 0.9, state_timer))
			level.player.velocity = (level.player.global_position - previous_position) / maxf(delta, 0.001)
			level.player.facing = 1
			if state_timer > 1.8 and not entrance_dismissing:
				entrance_dismissing = true
				entrance_overlay.dismiss(0.3)
			if state_timer > 1.35 and not intro_revealed:
				intro_revealed = true
				ritual_visual.hide()
				actor.show()
				cauldron.show()
				VFX.spawn(self, "smoke", actor.global_position + Vector2(0, -35), Vector2.RIGHT, Color("c4ed94"), 70.0)
			if state_timer >= 2.1:
				intro_finished = true
				level.boss_intro_running = false
				level.get_node("HUD").show()
				level.player.control_locked = false
				level.player.velocity = Vector2.ZERO
				if is_instance_valid(entrance_overlay):
					entrance_overlay.queue_free()
				_begin_action()
		State.CHANNELING:
			if not relocated and action_index > 0 and action_index % 2 == 0 and state_timer > 0.32:
				relocated = true
				_relocate()
			if state_timer >= (1.35 if phase == 0 else 1.12):
				_begin_cast()
		State.CASTING:
			if not cast_released:
				actor.visual.set_frame_and_progress(mini(3, int(state_timer / 0.46 * 4.0)), 0.0)
				actor.visual.pause()
			if not cast_released and state_timer >= 0.46:
				cast_released = true
				_release_attack()
			if state_timer >= 0.85:
				_set_state(State.RECOVERY)
				actor.play("idle")
		State.RECOVERY:
			if state_timer >= (2.7 if phase == 0 else 2.35):
				action_index += 1
				_begin_action()
		State.STAGGERED:
			if state_timer >= 4.5:
				action_index += 1
				_begin_action()
		State.DEFEATED:
			if state_timer >= 1.1 and not defeat_emitted:
				defeat_emitted = true
				defeated.emit()
	queue_redraw()

func is_combat_live() -> bool:
	return active and is_instance_valid(level) and not level.finished and level.player.hp > 0 and state not in [State.INTRO, State.DEFEATED]

func can_hurt_boss() -> bool:
	return is_combat_live() and state != State.CHANNELING

func _set_state(next_state: State) -> void:
	state = next_state
	state_timer = 0.0
	queue_redraw()

func _begin_action() -> void:
	current_attack = PHASE_PATTERNS[phase][action_index % PHASE_PATTERNS[phase].size()]
	_set_state(State.CHANNELING)
	relocated = false
	actor.play("idle")
	_announce_attack()

func _announce_attack() -> void:
	match current_attack:
		"skull": hint_changed.emit("Rebata a caveira com K quando ela brilhar!")
		"poison": hint_changed.emit("Saia das marcas no chão: veneno!")
		"wave": hint_changed.emit("Uma onda vem aí — pule com Espaço!")
		"stones": hint_changed.emit("Olhe as marcas: o teto vai cair!")
		"poison_wave": hint_changed.emit("Saia do veneno e pule a onda!")

func _begin_cast() -> void:
	_set_state(State.CASTING)
	cast_released = false
	actor.play("cast")
	actor.visual.pause()
	_announce_attack()

func _release_attack() -> void:
	actor.play("recover")
	sounds.play_effect("cast")
	match current_attack:
		"skull": _spawn_skull()
		"poison": _spawn_poison()
		"wave": _spawn_wave()
		"stones": _spawn_stones()
		"poison_wave":
			_spawn_poison()
			_spawn_wave()

func shield_blocked() -> void:
	if state != State.CHANNELING or not is_combat_live():
		return
	shield_flash = 0.3
	if shield_hint_cooldown <= 0.0:
		shield_hint_cooldown = 1.5
		hint_changed.emit("Barreira ativa — espere a abertura ou rebata a caveira!")

func _spawn_skull() -> Node2D:
	var spell := SPELL.new()
	spell.configure(self, actor.global_position + Vector2(-24 if not actor.visual.flip_h else 24, 0), level.player.global_position)
	add_child(spell)
	projectiles.append(spell)
	return spell

func _spawn_poison() -> void:
	var point: Vector2 = level.player.global_position.clamp(Vector2(4215, 365), Vector2(4990, 535))
	_add_hazard("poison", point)
	if phase >= 1:
		var second: Vector2 = (point + Vector2(110 if point.x < 4630 else -110, -65 if point.y > 450 else 65)).clamp(Vector2(4220, 365), Vector2(4980, 535))
		_add_hazard("poison", second)

func _spawn_wave() -> Node2D:
	return _add_hazard("wave", CAULDRON_POSITION)

func _add_hazard(kind: String, point: Vector2) -> Node2D:
	var hazard := HAZARD.new()
	hazard.configure(self, kind, point)
	add_child(hazard)
	hazards.append(hazard)
	return hazard

func _spawn_stones() -> void:
	var point: Vector2 = level.player.global_position
	var offsets: Array[float] = [0.0]
	if phase == 2:
		offsets.append(-104.0 if point.x > 4630 else 104.0)
	for offset in offsets:
		var rock := STALACTITE.new()
		rock.configure(level, Vector2(clampf(point.x + offset, 4210, 4990), 145), point.y, true, int(level.wave_index))
		add_child(rock)
		rock._begin_warning(level.player)
		boss_stalactites.append(rock)

func _on_player_attack(heading: Vector2) -> void:
	if not is_combat_live():
		return
	# One accepted punch reflects only the nearest approaching projectile.
	var closest: Node2D
	var distance := INF
	for spell in projectiles:
		if not is_instance_valid(spell) or spell.is_queued_for_deletion() or not spell.can_reflect(level.player, heading):
			continue
		var candidate: float = spell.global_position.distance_squared_to(level.player.global_position)
		if candidate < distance:
			distance = candidate
			closest = spell
	if is_instance_valid(closest):
		closest.reflect()

func reflection_feedback() -> void:
	reflected_count += 1
	sounds.play_effect("counter")
	VFX.spawn(level.player, "ring", level.player.global_position + Vector2(0, -45), Vector2.RIGHT, Color("fff0a1"), 45.0)
	_shake(2.2, 0.13)
	hint_changed.emit("Boa! A caveira vai atingir o caldeirão!")

func _overload_cauldron() -> void:
	if not is_combat_live():
		return
	overload_count += 1
	overload_flash = 0.85
	_set_state(State.STAGGERED)
	actor.play("hurt")
	sounds.play_effect("overload")
	_clear_attacks()
	VFX.spawn(self, "smoke", CAULDRON_POSITION + Vector2(0, -43), Vector2.RIGHT, Color("cbff79"), 95.0)
	VFX.spawn(self, "ring", CAULDRON_POSITION, Vector2.RIGHT, Color("f0ff9c"), 115.0)
	_shake(4.2, 0.28)
	hint_changed.emit("Caldeirão sobrecarregado! Ataque a Cuca!")

func boss_was_hit() -> void:
	var feedback := level.get_node_or_null("CombatFeedback")
	if is_instance_valid(feedback):
		feedback.hit(actor)
	if actor.hp <= 0:
		_defeat()
		return
	var next_phase := 2 if actor.hp <= actor.max_hp / 3 else 1 if actor.hp <= actor.max_hp * 2 / 3 else 0
	if next_phase > phase:
		phase = next_phase
		phase_changed.emit(phase)
		VFX.spawn(self, "ring", actor.global_position, Vector2.RIGHT, Color("bcf680"), 83.0)
		_shake(2.5, 0.2)

func _defeat() -> void:
	_set_state(State.DEFEATED)
	_clear_attacks()
	actor.play("death")
	actor.hurt_area.set_deferred("collision_layer", 0)
	hint_changed.emit("Cuca derrotada")
	_shake(3.6, 0.25)

func damage_player(amount: int, _source: String = "") -> bool:
	if not is_combat_live():
		return false
	var damaged: bool = level.player.take_damage(amount)
	if damaged:
		var feedback := level.get_node_or_null("CombatFeedback")
		if is_instance_valid(feedback):
			feedback.hit(level.player)
	return damaged

func hazard_activated(kind: String) -> void:
	if kind == "wave":
		sounds.play_effect("wave")

func _relocate() -> void:
	var hero: Node2D = level.player
	var destination := Vector2(4820, 470) if hero.global_position.x < 4600 else Vector2(4440, 420)
	if destination.distance_to(actor.position) < 100.0:
		return
	VFX.spawn(self, "smoke", actor.global_position + Vector2(0, -35), Vector2.RIGHT, Color("a4d56d"), 57.0)
	VFX.afterimage(actor, Color(0.66, 0.93, 0.39, 0.4))
	actor.position = destination
	actor.modulate.a = 0.0
	actor.create_tween().tween_property(actor, "modulate:a", 1.0, 0.28)
	VFX.spawn(self, "smoke", actor.global_position + Vector2(0, -35), Vector2.RIGHT, Color("b0d980"), 57.0)

func _update_facing() -> void:
	if state != State.DEFEATED:
		actor.visual.flip_h = level.player.global_position.x > actor.global_position.x

func _shake(strength: float, duration: float) -> void:
	var feedback := level.get_node_or_null("CombatFeedback")
	if not is_instance_valid(feedback):
		return
	if not is_instance_valid(feedback.camera):
		feedback.camera = level.player.get_node("Camera2D")
		feedback.camera_base = feedback.camera.offset
	feedback.shake_strength = maxf(feedback.shake_strength, strength)
	feedback.shake_remaining = maxf(feedback.shake_remaining, duration)

func _clear_attacks() -> void:
	for collection in [projectiles, hazards, boss_stalactites]:
		for effect in collection:
			if is_instance_valid(effect):
				effect.set_physics_process(false)
				effect.queue_free()
		collection.clear()

func _clean_arrays() -> void:
	for collection in [projectiles, hazards, boss_stalactites]:
		for index in range(collection.size() - 1, -1, -1):
			if not is_instance_valid(collection[index]) or collection[index].is_queued_for_deletion():
				collection.remove_at(index)

func _update_motes(delta: float) -> void:
	mote_clock -= delta
	if mote_clock <= 0.0 and state != State.DEFEATED:
		mote_clock = 0.08
		var angle := elapsed * 5.3
		motes.append({"point": CAULDRON_POSITION + Vector2(sin(angle) * 19, -52), "age": 0.0, "offset": sin(angle) * 9.0})
	for index in range(motes.size() - 1, -1, -1):
		motes[index]["age"] += delta
		motes[index]["point"] += Vector2(sin(elapsed * 2.0 + index) * 5.0, -22.0) * delta
		if motes[index]["age"] >= 1.2:
			motes.remove_at(index)

func _draw() -> void:
	if not active:
		return
	if state == State.CHANNELING:
		var point: Vector2 = actor.position + Vector2(0, -62)
		var pulse := 1.0 + sin(elapsed * 6.0) * 0.035
		draw_set_transform(point, 0.0, Vector2(0.67, 1.0) * pulse)
		draw_arc(Vector2.ZERO, 65.0, 0, TAU, 64, Color(0.44, 0.8, 0.23, 0.14), 9.0, true)
		draw_arc(Vector2.ZERO, 65.0, 0, TAU, 64, Color(0.71 + shield_flash * 0.8, 0.92, 0.44 + shield_flash, 0.66 + shield_flash), 1.4 + shield_flash * 8.0, true)
		draw_set_transform(Vector2.ZERO)
	if state == State.CASTING and not cast_released:
		var point: Vector2 = actor.position + Vector2(-40 if not actor.visual.flip_h else 40, -65)
		var progress := minf(state_timer / 0.46, 1.0)
		draw_circle(point, 8.0 + progress * 13.0, Color(0.55, 0.94, 0.2, 0.1 + progress * 0.12))
		draw_arc(point, 11.0 + progress * 11.0, 0, TAU, 32, Color(0.84, 1, 0.47, 0.75), 1.6, true)
	if state == State.STAGGERED:
		for index in range(3):
			var angle := elapsed * 3.6 + index * TAU / 3.0
			var point: Vector2 = actor.position + Vector2(sin(angle) * 28.0, -130.0 + cos(angle) * 6.0)
			draw_line(point - Vector2(3.5, 0), point + Vector2(3.5, 0), Color("fff0a0"), 1.7, true)
			draw_line(point - Vector2(0, 3.5), point + Vector2(0, 3.5), Color("fff0a0"), 1.7, true)
	for mote: Dictionary in motes:
		var fade := 1.0 - float(mote["age"]) / 1.2
		draw_circle(mote["point"], 1.2 + fade * 1.5, Color(0.73, 0.96, 0.3, fade * 0.55))
