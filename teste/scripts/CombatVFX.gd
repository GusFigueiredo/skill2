extends Node2D

var kind := "slash"
var tint := Color("ffe5a0")
var radius := 70.0
var duration := 0.3
var elapsed := 0.0

static func spawn(actor: Node2D, effect: String, point: Vector2, heading: Vector2, color: Color, size: float = 70.0) -> void:
	var visual = load("res://scripts/CombatVFX.gd").new()
	visual.kind = effect
	visual.tint = color
	visual.radius = size
	visual.duration = {"smoke": 0.55, "eruption": 1.4, "fire_burst": 0.65, "embers": 0.45}.get(effect, 0.3)
	actor.get_parent().add_child(visual)
	visual.global_position = point
	visual.rotation = heading.angle()
	visual.z_index = 15

static func afterimage(actor: Node2D, color: Color = Color(0.5, 0.85, 0.8, 0.32)) -> void:
	var source := actor.get_node("Sprite") as AnimatedSprite2D
	var ghost := Sprite2D.new()
	ghost.texture = source.sprite_frames.get_frame_texture(source.animation, source.frame)
	ghost.flip_h = source.flip_h
	ghost.scale = source.global_scale
	ghost.modulate = color
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	actor.get_parent().add_child(ghost)
	ghost.global_position = source.global_position
	var fade := ghost.create_tween()
	fade.tween_property(ghost, "modulate:a", 0.0, 0.22)
	fade.tween_callback(ghost.queue_free)

static func warning(canvas: Node2D, area: Rect2, progress: float, color: Color) -> void:
	var fill := color
	fill.a = 0.12 + progress * 0.18
	canvas.draw_rect(area, fill)
	var edge := color
	edge.a = 0.55 + progress * 0.45
	canvas.draw_rect(area, edge, false, 1.5, true)
	var forward := 1.0 if area.position.x >= 0.0 else -1.0
	for i in range(int(area.size.x / 32.0)):
		var x := forward * (16.0 + i * 32.0)
		var center := Vector2(x, area.get_center().y)
		canvas.draw_polyline(PackedVector2Array([center + Vector2(-forward * 6, -5), center + Vector2(forward * 2, 0), center + Vector2(-forward * 6, 5)]), edge, 2.0, true)

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var progress := clampf(elapsed / duration, 0.0, 1.0)
	var color := tint
	color.a = (1.0 - progress) * 0.85
	if kind in ["eruption", "fire_burst", "embers"]:
		var count := 24 if kind == "eruption" else (14 if kind == "fire_burst" else 5)
		for i in range(count):
			var heading := Vector2.from_angle(i * 2.399)
			var distance := radius * (0.25 + float(i % 5) * 0.15) * progress
			var point := heading * distance + Vector2(0, -progress * progress * radius * 0.55)
			var tail := point - heading * (8.0 + 18.0 * (1.0 - progress))
			draw_line(tail, point, Color(1, 0.3, 0.02, color.a * 0.5), 4.0 * (1.0 - progress) + 0.5, true)
			draw_circle(point, (2.0 + i % 3) * (1.0 - progress), Color(1, 0.85, 0.35, color.a))
		if kind != "embers":
			for i in range(3):
				var wave := clampf(progress * 1.8 - i * 0.22, 0.0, 1.0)
				draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.45))
				draw_arc(Vector2.ZERO, maxf(1.0, radius * wave), 0, TAU, 64, Color(1, 0.5, 0.08, (1.0 - wave) * color.a * 0.55), 3.0, true)
			draw_set_transform(Vector2.ZERO)
	elif kind == "smoke":
		for i in range(10):
			var heading := Vector2.from_angle(i * 2.4)
			var point := heading * radius * progress * 0.7 + Vector2(0, -progress * 18)
			var fog := color
			fog.a *= 0.24
			draw_circle(point, (7.0 + i % 3 * 3.0) * (0.6 + progress), fog)
	elif kind == "dash":
		for i in range(9):
			var point := Vector2(-radius * progress - i * 9.0, sin(i * 7.1) * 22.0)
			draw_line(point, point + Vector2(-25.0 * (1.0 - progress), 0), color, 2.0, true)
			draw_circle(point, 2.0 * (1.0 - progress), Color(1, 0.8, 0.25, color.a))
	elif kind == "ring":
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.45))
		draw_arc(Vector2.ZERO, radius * (0.2 + progress), 0, TAU, 48, Color(color, color.a * 0.2), 10.0 * (1.0 - progress), true)
		draw_arc(Vector2.ZERO, radius * (0.2 + progress), 0, TAU, 48, color, 2.5, true)
	else:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.65))
		var sweep := -1.2 + progress * 1.6
		draw_arc(Vector2.ZERO, radius, sweep - 1.2, sweep + 0.6, 32, Color(color, color.a * 0.18), 16.0, true)
		draw_arc(Vector2.ZERO, radius, sweep - 0.9, sweep + 0.6, 32, color, 5.0 * (1.0 - progress) + 1.0, true)
		draw_arc(Vector2.ZERO, radius - 5, sweep - 0.6, sweep + 0.6, 24, Color(1, 1, 0.9, color.a), 2.0, true)
