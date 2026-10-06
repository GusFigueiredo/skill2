extends Node2D

var player: CharacterBody2D
var game_manager: Node
var travel_direction := Vector2.LEFT
var speed: float = 300.0
var damage: int = 2
var lifetime: float = 6.0
const FIREBALL_TEXTURE := preload("res://sprites/characters/boitata/projectile.png")

func _ready() -> void:
	add_to_group("fireballs")
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = FIREBALL_TEXTURE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(0.5, 0.5)
	# Keep the bright head of the projectile at its damage position.
	sprite.offset.x = -(FIREBALL_TEXTURE.get_width() * 0.5 - FIREBALL_TEXTURE.get_height() * 0.3)
	sprite.rotation = travel_direction.angle()
	add_child(sprite)

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
		preload("res://scripts/CombatVFX.gd").spawn(self, "ring", global_position, Vector2.RIGHT, Color("ffac42"), 42.0)
		player.take_damage(damage)
		queue_free()
	lifetime -= delta
	queue_redraw()
	if lifetime <= 0.0:
		queue_free()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, travel_direction.angle())
	var pulse := 1.0 + sin(lifetime * 18.0) * 0.08
	for i in range(4, 0, -1):
		draw_circle(Vector2.ZERO, (9.0 + i * 6.0) * pulse, Color(1, 0.35, 0.04, 0.035 * (5 - i)))
	for i in range(7):
		var flicker := sin(lifetime * 15.0 + i * 2.4)
		var point := Vector2(-18.0 - i * 10.0, flicker * (4.0 + i))
		draw_circle(point, 3.0 - i * 0.3, Color(1, 0.65 + i * 0.03, 0.12, 0.6 * (1.0 - i / 7.0)))
