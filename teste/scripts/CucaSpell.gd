extends Node2D

const FRAMES := preload("res://scripts/CucaFrames.gd")
const COUNTER_RADIUS := 109.0
const KEY_PROMPT := preload("res://scripts/JaguarMashPrompt.gd")
var fight: Node2D
var direction := Vector2.LEFT
var speed := 205.0
var reflected := false
var age := 0.0
var sprite: Sprite2D
var trail: Array[Dictionary] = []
var trail_clock := 0.0
var counter_prompt: Control

func configure(controller: Node2D, start: Vector2, target: Vector2) -> void:
	fight = controller
	position = start
	direction = (target - start).normalized()

func _ready() -> void:
	name = "GreenSkull"
	z_index = 8
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite = Sprite2D.new()
	sprite.texture = FRAMES.skull_texture()
	sprite.scale = Vector2.ONE * (43.0 / sprite.texture.get_height())
	sprite.position = Vector2(0, -53)
	sprite.flip_h = direction.x > 0.0
	_align_head()
	add_child(sprite)
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	sprite.material = material
	counter_prompt = KEY_PROMPT.new()
	add_child(counter_prompt)
	counter_prompt.position = Vector2(-83, -194)
	counter_prompt.scale = Vector2.ONE * 0.31
	counter_prompt.icon.material = material
	counter_prompt.hide()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(fight) or not fight.is_combat_live():
		queue_free()
		return
	age += delta
	var previous := global_position
	if reflected:
		direction = (fight.CAULDRON_POSITION - global_position).normalized()
	global_position += direction * speed * delta
	sprite.flip_h = direction.x > 0.0
	_align_head()
	sprite.position.y = -53.0 + sin(age * 12.0) * 2.5
	trail_clock -= delta
	if trail_clock <= 0.0:
		trail_clock = 0.035
		trail.append({"point": global_position + Vector2(0, -53), "age": 0.0})
	for index in range(trail.size() - 1, -1, -1):
		trail[index]["age"] += delta
		if trail[index]["age"] > 0.32:
			trail.remove_at(index)
	if reflected:
		if _distance_to_segment(fight.CAULDRON_POSITION, previous, global_position) < 23.0:
			fight._overload_cauldron()
			queue_free()
			return
	else:
		var hero: Node2D = fight.level.player
		counter_prompt.visible = can_reflect(hero, hero._attack_heading())
		if float(hero.jump_height) < 65.0 and _distance_to_segment(hero.global_position, previous, global_position) < 25.0:
			fight.damage_player(2, "skull")
			queue_free()
			return
	if age > 8.0 or global_position.x < 4060.0 or global_position.x > 5150.0:
		queue_free()
	queue_redraw()

func can_reflect(hero: Node2D, heading: Vector2) -> bool:
	if reflected or not is_instance_valid(fight) or not fight.is_combat_live():
		return false
	var delta := global_position - hero.global_position
	if delta.length() > COUNTER_RADIUS or absf(delta.y) > 40.0 or float(hero.jump_height) > 85.0:
		return false
	return delta.normalized().dot(heading) > 0.25 and direction.dot(delta) < 0.0

func reflect() -> void:
	if reflected:
		return
	reflected = true
	counter_prompt.hide()
	speed = 570.0
	age = 0.0
	sprite.modulate = Color("fff6a8")
	fight.reflection_feedback()

func _align_head() -> void:
	# The texture includes a long tail. Keep the skull, the hit point and
	# the gold counter ring together when the projectile changes direction.
	sprite.position.x = (-1.0 if sprite.flip_h else 1.0) * 36.0

static func _distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	return point.distance_to(Geometry2D.get_closest_point_to_segment(point, start, finish))

func _draw() -> void:
	var color := Color("e8f79a") if reflected else Color("92e951")
	for spark: Dictionary in trail:
		var fraction := 1.0 - float(spark["age"]) / 0.32
		draw_circle(to_local(spark["point"]), 7.0 * fraction, Color(color, fraction * 0.3))
	if not reflected and is_instance_valid(fight):
		var hero: Node2D = fight.level.player
		if can_reflect(hero, hero._attack_heading()):
			draw_arc(Vector2(0, -53), 29.0 + sin(age * 24.0) * 2.0, 0.0, TAU, 40, Color("ffe38a"), 2.0, true)
			draw_circle(Vector2(0, -53), 33.0, Color(1, 0.9, 0.4, 0.1))
