extends Node2D

var lifetime: float = 1.5
var damage_interval: float = 1.0
var damage_timer: float = 0.0
var width: float = 55.0
var segments: Array[Dictionary] = []
var player: CharacterBody2D
var game_manager: Node
var emitting: bool = true

func _ready() -> void:
	add_to_group("flame_trails")

func add_segment(start: Vector2, end: Vector2) -> void:
	if start.distance_squared_to(end) > 0.01:
		segments.append({"start": start, "end": end, "remaining": lifetime})
		queue_redraw()

func _physics_process(delta: float) -> void:
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
		var intensity := minf(1.0, float(segment["remaining"]) / 0.3)
		draw_line(start, end, Color(1.0, 0.2, 0.02, 0.65 * intensity), width, true)
		draw_line(start, end, Color(1.0, 0.65, 0.05, 0.85 * intensity), width * 0.5, true)
		draw_line(start, end, Color(1.0, 0.95, 0.35, intensity), width * 0.15, true)
