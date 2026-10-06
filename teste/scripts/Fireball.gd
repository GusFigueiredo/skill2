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
		player.take_damage(damage)
		queue_free()
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
