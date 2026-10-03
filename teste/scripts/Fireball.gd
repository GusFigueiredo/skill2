extends Node2D

var player: CharacterBody2D
var game_manager: Node
var travel_direction := Vector2.LEFT
var speed: float = 300.0
var damage: int = 2
var lifetime: float = 6.0

func _ready() -> void:
	add_to_group("fireballs")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(game_manager) or game_manager.finished or player.hp <= 0:
		queue_free()
		return
	var previous := global_position
	global_position += travel_direction * speed * delta
	var path := global_position - previous
	var fraction := 0.0
	if path.length_squared() > 0.0:
		fraction = clampf((player.global_position - previous).dot(path) / path.length_squared(), 0.0, 1.0)
	if (previous + path * fraction).distance_to(player.global_position) <= 24.0:
		player.take_damage(damage)
		queue_free()
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	draw_line(-travel_direction * 25.0, Vector2.ZERO, Color(1.0, 0.25, 0.02, 0.6), 14.0, true)
	draw_circle(Vector2.ZERO, 12.0, Color(1.0, 0.35, 0.03))
	draw_circle(Vector2.ZERO, 7.0, Color(1.0, 0.85, 0.2))
