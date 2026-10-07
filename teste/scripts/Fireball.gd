extends Node2D

var player: CharacterBody2D
var game_manager: Node
var travel_direction := Vector2.LEFT
var speed: float = 300.0
var damage: int = 2
var lifetime: float = 6.0
var animation_elapsed: float = 0.0
const FIREBALL_TEXTURE := preload("res://sprites/characters/boitata/projectile.png")
var hitbox: CollisionShape2D

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
	var area := Area2D.new()
	area.name = "Hitbox"
	area.monitoring = false
	area.collision_layer = 0
	area.collision_mask = 0
	sprite.add_child(area)
	hitbox = CollisionShape2D.new()
	var opaque := FIREBALL_TEXTURE.get_image().get_used_rect()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(opaque.size)
	hitbox.shape = rectangle
	hitbox.position = Vector2(opaque.get_center()) - Vector2(FIREBALL_TEXTURE.get_size()) * 0.5 + sprite.offset
	area.add_child(hitbox)

func _physics_process(delta: float) -> void:
	animation_elapsed += delta
	$Sprite.flip_v = int(animation_elapsed * 12.0) % 2 == 1
	if not is_instance_valid(player) or not is_instance_valid(game_manager) or game_manager.finished or player.hp <= 0:
		queue_free()
		return
	var previous := global_position
	global_position += travel_direction * speed * delta
	if _swept_hits_player(previous):
		preload("res://scripts/CombatVFX.gd").spawn(self, "ring", global_position, Vector2.RIGHT, Color("ffac42"), 42.0)
		player.take_damage(damage)
		queue_free()
	lifetime -= delta
	queue_redraw()
	if lifetime <= 0.0:
		queue_free()

func _hitbox_polygon(at_position: Vector2) -> PackedVector2Array:
	var half: Vector2 = hitbox.shape.size * 0.5
	var points := PackedVector2Array([-half, Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)])
	for i in points.size():
		points[i] = hitbox.global_transform * points[i] + at_position - global_position
	return points

func _swept_hits_player(previous: Vector2) -> bool:
	# Sweep the scaled, rotated sprite bounds, including its visible flame tail.
	var points := _hitbox_polygon(previous)
	points.append_array(_hitbox_polygon(global_position))
	var sweep := Geometry2D.convex_hull(points)
	var body := player.get_node("HurtArea").get_child(0) as CollisionShape2D
	var half: Vector2 = body.shape.size * 0.5
	var target := PackedVector2Array([-half, Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)])
	for i in target.size():
		target[i] = body.global_transform * target[i] - Vector2(0, player.jump_height)
	return not Geometry2D.intersect_polygons(sweep, target).is_empty()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, travel_direction.angle())
	var pulse := 1.0 + sin(lifetime * 18.0) * 0.08
	for i in range(4, 0, -1):
		draw_circle(Vector2.ZERO, (9.0 + i * 6.0) * pulse, Color(1, 0.35, 0.04, 0.035 * (5 - i)))
	for i in range(7):
		var flicker := sin(lifetime * 15.0 + i * 2.4)
		var point := Vector2(-18.0 - i * 10.0, flicker * (4.0 + i))
		draw_circle(point, 3.0 - i * 0.3, Color(1, 0.65 + i * 0.03, 0.12, 0.6 * (1.0 - i / 7.0)))
