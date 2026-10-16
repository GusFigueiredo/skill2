extends Node2D

const FRAMES := preload("res://scripts/CucaFrames.gd")
const VFX := preload("res://scripts/CombatVFX.gd")

var controller: Node2D
var max_hp := 18
var hp := 18
var visual: AnimatedSprite2D
var hurt_area: Area2D
var hurt_flash := 0.0
var combat_bounds := Rect2(-29, -104, 58, 104)

func _ready() -> void:
	name = "Cuca"
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual = AnimatedSprite2D.new()
	visual.name = "Sprite"
	visual.sprite_frames = FRAMES.build(125.0)
	visual.position = FRAMES.grounded_offset(visual.sprite_frames)
	add_child(visual)
	visual.play("idle")
	hurt_area = Area2D.new()
	hurt_area.name = "HurtArea"
	hurt_area.collision_layer = 8
	hurt_area.collision_mask = 0
	hurt_area.monitoring = false
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = combat_bounds.size
	shape.shape = rectangle
	shape.position = combat_bounds.get_center()
	hurt_area.add_child(shape)
	add_child(hurt_area)

func _process(delta: float) -> void:
	hurt_flash = maxf(0.0, hurt_flash - delta)
	visual.modulate = Color(1.6, 1.55, 1.0) if hurt_flash > 0.0 else Color.WHITE
	if hp > 0 and visual.animation in [&"hurt", &"recover"] and not visual.is_playing():
		visual.play("idle")
	queue_redraw()

func play(animation: StringName) -> void:
	if visual.animation != animation or not visual.is_playing():
		visual.play(animation)

func take_damage(amount: int) -> bool:
	if amount <= 0 or hp <= 0 or not is_instance_valid(controller):
		return false
	if not controller.can_hurt_boss():
		controller.shield_blocked()
		return false
	var hero: Node2D = controller.level.player
	# A jump changes the hero's visual height, never their floor lane.
	if absf(hero.global_position.y - global_position.y) > 55.0 or float(hero.jump_height) > 125.0:
		return false
	hp = maxi(0, hp - amount)
	hurt_flash = 0.13
	VFX.spawn(self, "slash", global_position + Vector2(0, -64), Vector2.RIGHT, Color("e1ff8b"), 44.0)
	controller.boss_was_hit()
	return true

func _draw() -> void:
	if hp > 0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.28))
		draw_circle(Vector2.ZERO, 32.0, Color(0, 0.015, 0.005, 0.4))
		draw_set_transform(Vector2.ZERO)
