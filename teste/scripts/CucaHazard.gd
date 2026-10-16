extends Node2D

var fight: Node2D
var kind := "poison"
var warning := 0.95
var duration := 4.8
var age := 0.0
var activated := false
var radius := 51.0
var previous_radius := 0.0
var damaged := false
var hit_cooldown := 0.0

func configure(controller: Node2D, effect: String, point: Vector2) -> void:
	fight = controller
	kind = effect
	position = point
	if kind == "wave":
		warning = 1.15
		duration = 4.8
		radius = 35.0

func _ready() -> void:
	name = "PoisonPool" if kind == "poison" else "CauldronWave"
	z_index = -1
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	self.material = material

func _physics_process(delta: float) -> void:
	if not is_instance_valid(fight) or not fight.is_combat_live():
		queue_free()
		return
	age += delta
	hit_cooldown = maxf(0.0, hit_cooldown - delta)
	if age < warning:
		queue_redraw()
		return
	if not activated:
		activated = true
		fight.hazard_activated(kind)
	var hero: Node2D = fight.level.player
	if kind == "poison":
		var delta_position := hero.global_position - global_position
		var distance := Vector2(delta_position.x, delta_position.y / 0.55).length()
		if distance <= radius * 0.86 and float(hero.jump_height) < 35.0 and hit_cooldown <= 0.0:
			if fight.damage_player(1, "poison"):
				hit_cooldown = 1.1
	else:
		previous_radius = radius
		radius += delta * 215.0
		var point := hero.global_position - global_position
		var distance := Vector2(point.x, point.y / 0.55).length()
		if not damaged and distance >= previous_radius - 19.0 and distance <= radius + 19.0:
			if float(hero.jump_height) < 28.0:
				damaged = fight.damage_player(2, "wave")
	if age >= warning + duration:
		queue_free()
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))
	if not activated:
		var progress := clampf(age / warning, 0.0, 1.0)
		var size := radius if kind == "poison" else 70.0
		draw_circle(Vector2.ZERO, size, Color(0.77, 0.69, 0.22, 0.035 + progress * 0.1))
		draw_arc(Vector2.ZERO, size, 0.0, TAU, 60, Color(0.98, 0.82, 0.36, 0.55 + progress * 0.4), 1.8, true)
		draw_arc(Vector2.ZERO, maxf(1.0, size * (1.0 - progress)), 0.0, TAU, 50, Color(1, 0.9, 0.56, 0.65), 1.0, true)
		for index in range(4):
			var direction := Vector2.from_angle(index * PI * 0.5 + PI * 0.25)
			draw_line(direction * (size - 7.0), direction * (size + 7.0), Color("ffe799"), 1.5, true)
	elif kind == "poison":
		var fade := clampf((warning + duration - age) / 0.75, 0.0, 1.0)
		draw_circle(Vector2.ZERO, radius, Color(0.08, 0.18, 0.035, 0.77 * fade))
		draw_circle(Vector2.ZERO, radius - 5.0, Color(0.3, 0.58, 0.06, 0.4 * fade))
		draw_arc(Vector2.ZERO, radius - 2.0 + sin(age * 5.0), 0, TAU, 60, Color(0.61, 0.83, 0.2, 0.7 * fade), 2.0, true)
		for index in range(9):
			var seed_angle := float(index) * 2.399
			var point := Vector2.from_angle(seed_angle) * (10.0 + index % 4 * 9.0)
			var bubble := fposmod(age * 1.3 + float(index) * 0.23, 1.0)
			draw_arc(point, 1.0 + bubble * 5.0, 0, TAU, 12, Color(0.8, 1, 0.35, (1.0 - bubble) * 0.6 * fade), 1.0, true)
	else:
		var fade := clampf((warning + duration - age) / 0.7, 0.0, 1.0)
		draw_arc(Vector2.ZERO, radius, 0, TAU, 120, Color(0.41, 0.8, 0.12, 0.13 * fade), 21.0, true)
		draw_arc(Vector2.ZERO, radius, 0, TAU, 120, Color(0.66, 0.96, 0.26, 0.85 * fade), 5.0, true)
		draw_arc(Vector2.ZERO, maxf(1.0, radius - 7.0), 0, TAU, 120, Color(0.95, 1, 0.63, 0.68 * fade), 1.3, true)
	draw_set_transform(Vector2.ZERO)
