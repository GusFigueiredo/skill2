extends Node2D

const DURATION := 0.45
var elapsed: float = 0.0
var tint := Color("ffd480")

static func spawn(actor: Node2D, _amount: int) -> void:
	var impact := load("res://scripts/DamageImpact.gd").new() as Node2D
	impact.tint = Color("ff8875") if actor.is_in_group("player") else Color("ffd480")
	actor.get_parent().add_child(impact)
	impact.global_position = actor.get_node("Sprite").global_position
	impact.z_index = 20
	var visual = actor.get_node("Sprite")
	if visual.has_method("flash_damage"):
		visual.flash_damage()

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= DURATION:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var progress := elapsed / DURATION
	var color := tint
	color.a = 1.0 - progress
	if progress < 0.28:
		var flash := 1.0 - progress / 0.28
		draw_circle(Vector2.ZERO, 17.0 + progress * 30.0, Color(tint, flash * 0.16))
		draw_line(Vector2(-20, 0), Vector2(20, 0), Color(1, 1, 0.9, flash), 3.0, true)
		draw_line(Vector2(0, -14), Vector2(0, 14), Color(1, 1, 0.9, flash), 2.0, true)
	for index in range(8):
		var direction := Vector2.from_angle(index * TAU / 8.0 + 0.2)
		var start := direction * (5.0 + 38.0 * progress)
		draw_line(start, start + direction * (9.0 * (1.0 - progress)), color, 2.0)
	if progress < 0.5:
		draw_arc(Vector2.ZERO, 4.0 + progress * 38.0, 0, TAU, 24, color, 1.5)
