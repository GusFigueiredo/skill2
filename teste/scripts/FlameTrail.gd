extends Node2D

var lifetime: float = 1.5
var damage_interval: float = 1.0
var damage_timer: float = 0.0
var width: float = 55.0
var segments: Array[Dictionary] = []
var player: CharacterBody2D
var game_manager: Node
var emitting: bool = true
var visual_time: float = 0.0

func _ready() -> void:
	add_to_group("flame_trails")

func add_segment(start: Vector2, end: Vector2) -> void:
	if start.distance_squared_to(end) > 0.01:
		segments.append({"start": start, "end": end, "remaining": lifetime})
		queue_redraw()

func _physics_process(delta: float) -> void:
	visual_time += delta
	if not is_instance_valid(player) or not is_instance_valid(game_manager) or game_manager.finished or player.hp <= 0:
		queue_free()
		return
	damage_timer = maxf(0.0, damage_timer - delta)
	for index in range(segments.size() - 1, -1, -1):
		segments[index]["remaining"] -= delta
		if segments[index]["remaining"] <= 0.0:
			segments.remove_at(index)
	if damage_timer <= 0.0 and touches(player.global_position):
		if player.take_damage(1):
			damage_timer = damage_interval
	queue_redraw()
	if segments.is_empty() and not emitting:
		queue_free()

func touches(point: Vector2) -> bool:
	for segment in segments:
		var start: Vector2 = segment["start"]
		var end: Vector2 = segment["end"]
		var path := end - start
		var fraction := clampf((point - start).dot(path) / path.length_squared(), 0.0, 1.0)
		if point.distance_to(start + path * fraction) <= width / 2.0 + 6.0:
			return true
	return false

func _draw() -> void:
	for segment in segments:
		var start: Vector2 = to_local(segment["start"])
		var end: Vector2 = to_local(segment["end"])
		var intensity := minf(1.0, float(segment["remaining"]) / 0.45)
		# The glowing footprint follows the existing damage width.
		draw_line(start, end, Color(1, 0.18, 0.01, 0.18 * intensity), width * 1.35, true)
		draw_line(start, end, Color(0.65, 0.09, 0.015, 0.5 * intensity), width, true)
		draw_line(start, end, Color(1, 0.55, 0.035, 0.65 * intensity), width * 0.5, true)
		var count := maxi(1, ceili(start.distance_to(end) / 12.0))
		for index in range(count):
			var point := start.lerp(end, (index + 0.5) / float(count))
			var seed := point.x * 0.13 + point.y * 0.21
			var flicker := sin(visual_time * 15.0 + seed)
			var sway := sin(visual_time * 9.0 + seed * 1.7)
			var height := (27.0 + flicker * 10.0) * intensity
			# Nested curved silhouettes create tongues of flame rather than a solid stripe.
			for layer in range(3):
				var scale_factor := 1.0 - layer * 0.24
				var flame := PackedVector2Array([
					Vector2(-10, 3), Vector2(-9, -height * 0.3),
					Vector2(-4 + sway * 4, -height * 0.65),
					Vector2(sway * 9, -height),
					Vector2(5 + sway * 3, -height * 0.48), Vector2(10, 3)])
				for vertex in flame.size():
					flame[vertex] = point + flame[vertex] * scale_factor
				var color: Color = [Color(1, 0.22, 0.015, 0.7), Color(1, 0.62, 0.035, 0.85), Color(1, 0.93, 0.5, 0.9)][layer]
				color.a *= intensity
				draw_colored_polygon(flame, color)
			var rise := fmod(visual_time * 36.0 + absf(seed) * 9.0, 52.0)
			var ember := point + Vector2(sway * 12, -height - rise)
			draw_circle(ember, 1.8, Color(1, 0.8, 0.3, (1.0 - rise / 52.0) * intensity))
			draw_circle(point + Vector2(sway * 7, -45 - rise * 0.5), 6 + rise * 0.1, Color(0.12, 0.08, 0.065, 0.08 * intensity))
