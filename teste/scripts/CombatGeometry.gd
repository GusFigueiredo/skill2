extends RefCounted

static func setup(actor: CharacterBody2D, enemy: bool) -> Rect2:
	var visual := actor.get_node("Sprite") as AnimatedSprite2D
	var bounds := Rect2()
	var first := true
	for index in visual.sprite_frames.get_frame_count("idle"):
		var image := visual.sprite_frames.get_frame_texture("idle", index).get_image()
		var used := Rect2(image.get_used_rect())
		used.position = visual.position + (used.position - Vector2(image.get_size()) * 0.5) * visual.scale
		used.size *= visual.scale
		bounds = used if first else bounds.merge(used)
		first = false
	# Ground movement uses the footprint; hits use the raised body separately.
	var width := bounds.size.x * 0.7
	var body := actor.get_node("CollisionShape2D") as CollisionShape2D
	var footprint := RectangleShape2D.new()
	footprint.size = Vector2(width, maxf(16.0, bounds.size.y * 0.22))
	body.shape = footprint
	body.position = Vector2.ZERO
	var hurt := Area2D.new()
	hurt.name = "HurtArea"
	hurt.collision_layer = 8 if enemy else 16
	hurt.collision_mask = 0
	hurt.monitoring = false
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width, bounds.size.y * 0.9)
	shape.shape = rectangle
	shape.position = Vector2(0, bounds.get_center().y)
	hurt.add_child(shape)
	actor.add_child(hurt)
	if enemy:
		var contact := actor.get_node("DamageArea").get_child(0) as CollisionShape2D
		contact.shape = footprint.duplicate()
	return bounds
