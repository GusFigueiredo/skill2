extends Node2D

enum State { HANGING, WARNING, FALLING, SHATTERED }

const FRAMES := preload("res://scripts/CaveStalactiteFrames.gd")
const WARNING_SECONDS := 0.85
const TRIGGER_HALF_WIDTH := 42.0
const HANGING_HEIGHT := 92.0
const FALL_ACCELERATION := 1380.0
const HALF_WIDTH := 13.0
const DEPTH_TOLERANCE := 28.0

var state: State = State.HANGING
var state_timer := 0.0
var elapsed := 0.0
var level: Node2D
var section := 0
var falls := true
var triggered := false
var hit_attempted := false
var damage_dealt := false
var landing_y := 460.0
var tip_y := HANGING_HEIGHT
var fall_speed := 0.0
var source_scale := 1.0
var visual: AnimatedSprite2D
var ceiling_cap: Sprite2D
var sound := preload("res://scripts/SoundEffects.gd").new()
var debris: Array[Dictionary] = []
var dust_clock := 0.0

## Configure before adding to the cave. ceiling_position is the top attachment.
func configure(cave: Node2D, ceiling_position: Vector2, floor_y: float, can_fall: bool, section_index: int) -> void:
	level = cave
	position = ceiling_position
	landing_y = floor_y
	falls = can_fall
	section = section_index

func _ready() -> void:
	name = "FallingStalactite" if falls else "CeilingStalactite"
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 5
	visual = AnimatedSprite2D.new()
	visual.name = "Sprite"
	visual.sprite_frames = FRAMES.build(HANGING_HEIGHT)
	source_scale = float(visual.sprite_frames.get_meta("source_scale"))
	visual.centered = false
	visual.scale = Vector2.ONE * source_scale
	visual.position = Vector2(-120.0 * source_scale, 0)
	visual.play("hanging")
	add_child(visual)
	ceiling_cap = Sprite2D.new()
	ceiling_cap.texture = FRAMES.ceiling_cap()
	ceiling_cap.centered = false
	ceiling_cap.scale = visual.scale
	ceiling_cap.position = visual.position
	ceiling_cap.visible = false
	add_child(ceiling_cap)
	add_child(sound)
	sound.setup({"crack": "res://soundeffect/Feedback/hit.wav", "impact": "res://soundeffect/Feedback/hit.wav"}, {"crack": -15.0, "impact": -4.0})
	(sound.players["crack"] as AudioStreamPlayer).pitch_scale = 1.65
	(sound.players["impact"] as AudioStreamPlayer).pitch_scale = 0.58

func _physics_process(delta: float) -> void:
	elapsed += delta
	_update_debris(delta)
	if not is_instance_valid(level):
		return
	var hero := level.get_node_or_null("Player") as Node2D
	if not is_instance_valid(hero) or int(hero.get("hp")) <= 0 or level.get("finished") == true:
		queue_redraw()
		return
	state_timer += delta
	match state:
		State.HANGING:
			if _can_trigger(hero):
				_begin_warning(hero)
		State.WARNING:
			visual.position.x = -120.0 * source_scale + sin(state_timer * 73.0) * (0.6 + state_timer * 1.8)
			if state_timer >= WARNING_SECONDS * 0.58:
				visual.frame = 1
			dust_clock -= delta
			if dust_clock <= 0:
				dust_clock = 0.065
				_emit_dust(Vector2(sin(elapsed * 31.0) * 10.0, 73.0), 1, false)
			if state_timer >= WARNING_SECONDS:
				_begin_fall()
		State.FALLING:
			var previous_tip := tip_y
			fall_speed += FALL_ACCELERATION * delta
			tip_y = minf(landing_y - global_position.y, tip_y + fall_speed * delta)
			visual.position = Vector2(-61.5 * source_scale, tip_y - 224.0 * source_scale)
			_try_hit(hero, previous_tip, tip_y)
			if global_position.y + tip_y >= landing_y - 0.01:
				_shatter()
		State.SHATTERED:
			if state_timer > 6.0:
				visual.modulate.a = maxf(0.25, 1.0 - (state_timer - 6.0) * 0.16)
	queue_redraw()

func _can_trigger(hero: Node2D) -> bool:
	if not falls or triggered or level.get("wave_index") != section:
		return false
	if level.get("boss_intro_running") == true or hero.get("is_falling") == true:
		return false
	# Passing under the ceiling attachment triggers the trap in every
	# walkable lane; its old configured floor depth must not limit it.
	return absf(hero.global_position.x - global_position.x) <= TRIGGER_HALF_WIDTH

func _begin_warning(hero: Node2D = null) -> void:
	# Capture only once. The ring and the falling rock keep this target,
	# leaving the player time to move aside rather than tracking them.
	if is_instance_valid(hero):
		landing_y = hero.global_position.y
	triggered = true
	state = State.WARNING
	state_timer = 0.0
	visual.play("cracking")
	visual.pause()
	sound.play_effect("crack")
	_emit_dust(Vector2(0, 65), 8, false)

func _begin_fall() -> void:
	state = State.FALLING
	state_timer = 0.0
	fall_speed = 80.0
	tip_y = HANGING_HEIGHT
	visual.play("falling")
	visual.position = Vector2(-61.5 * source_scale, tip_y - 224.0 * source_scale)
	ceiling_cap.visible = true
	_emit_dust(Vector2(0, 42), 12, false)

## Sweep the descending body so low frame rates cannot tunnel through the hero.
## Lane depth is independent of the sprite's height; jumping changes only height.
func _try_hit(hero: Node2D, previous_tip: float, current_tip: float) -> void:
	if hit_attempted or not falls or state != State.FALLING:
		return
	if absf(hero.global_position.y - landing_y) > DEPTH_TOLERANCE:
		return
	var body: Rect2 = hero.get("combat_bounds")
	if body.size.x <= 0.0 or body.size.y <= 0.0:
		body = Rect2(-22.0, -84.0, 44.0, 84.0)
	var jump := float(hero.get("jump_height"))
	body.position += hero.global_position - Vector2(0, jump)
	var sweep := Rect2(
		Vector2(global_position.x - HALF_WIDTH, global_position.y + previous_tip - 224.0 * source_scale),
		Vector2(HALF_WIDTH * 2.0, current_tip - previous_tip + 224.0 * source_scale)
	)
	if not sweep.intersects(body):
		return
	hit_attempted = true
	var amount := ceili(float(hero.get("max_hp")) * 0.5)
	damage_dealt = bool(hero.take_damage(amount))
	if damage_dealt:
		var feedback := level.get_node_or_null("CombatFeedback")
		if is_instance_valid(feedback):
			feedback.hit(hero)

func _shatter() -> void:
	state = State.SHATTERED
	state_timer = 0.0
	visual.position = Vector2(-120.0 * source_scale, landing_y - global_position.y - 356.0 * source_scale)
	visual.play("shatter")
	sound.play_effect("impact")
	_emit_dust(Vector2(0, landing_y - global_position.y), 22, true)

func _emit_dust(point: Vector2, count: int, burst: bool) -> void:
	for index in range(count):
		var seed_angle := float(debris.size() + index) * 2.399 + elapsed * 1.7
		var velocity := Vector2(sin(seed_angle) * (64.0 if burst else 15.0), -38.0 - absf(cos(seed_angle)) * 63.0) if burst else Vector2(sin(seed_angle) * 18.0, 20.0)
		debris.append({"point": point + Vector2(sin(seed_angle) * 11.0, 0), "velocity": velocity, "age": 0.0, "duration": 0.6 if burst else 0.9, "size": 1.2 + index % 3, "burst": burst})

func _update_debris(delta: float) -> void:
	for index in range(debris.size() - 1, -1, -1):
		var piece: Dictionary = debris[index]
		piece["age"] += delta
		if piece["age"] >= piece["duration"]:
			debris.remove_at(index)
			continue
		piece["velocity"].y += (230.0 if piece["burst"] else 100.0) * delta
		piece["point"] += piece["velocity"] * delta

func _draw() -> void:
	if state in [State.WARNING, State.FALLING]:
		var progress := clampf(state_timer / WARNING_SECONDS, 0.0, 1.0) if state == State.WARNING else 1.0
		var point := Vector2(0, landing_y - global_position.y)
		draw_set_transform(point, 0, Vector2(1.0, 0.34))
		draw_circle(Vector2.ZERO, 28.0, Color(0.025, 0.04, 0.022, 0.2 + progress * 0.32))
		draw_arc(Vector2.ZERO, 30.0 + sin(elapsed * 17.0) * 1.5, 0.0, TAU, 40, Color(0.88, 0.75, 0.31, 0.28 + progress * 0.55), 1.8, true)
		draw_set_transform(Vector2.ZERO)
	for piece: Dictionary in debris:
		var alpha := (1.0 - float(piece["age"]) / float(piece["duration"])) * 0.72
		draw_rect(Rect2(piece["point"], Vector2.ONE * float(piece["size"])), Color(0.53, 0.58, 0.44, alpha))
