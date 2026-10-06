extends Control

var emitters: Array[CPUParticles2D] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var glow := GradientTexture2D.new()
	glow.width = 32
	glow.height = 32
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.5)
	glow.fill_to = Vector2(1.0, 0.5)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.15, 0.45, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.8), Color(1, 1, 1, 0.15), Color(1, 1, 1, 0)])
	glow.gradient = gradient
	_add_particles("Fireflies", 44, Color("efd481"), glow, 0.24, 0.56, 7.0, 15.0)
	_add_particles("ForestMotes", 22, Color("79c5c0"), glow, 0.08, 0.18, 3.0, 8.0)
	resized.connect(_fit_emitters)
	_fit_emitters()

func _add_particles(label: String, count: int, tint: Color, texture: Texture2D, minimum_scale: float, maximum_scale: float, minimum_speed: float, maximum_speed: float) -> void:
	var particles := CPUParticles2D.new()
	particles.name = label
	particles.amount = count
	particles.lifetime = 12.0
	particles.preprocess = 12.0
	particles.texture = texture
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.direction = Vector2.UP
	particles.spread = 65.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = minimum_speed
	particles.initial_velocity_max = maximum_speed
	particles.scale_amount_min = minimum_scale
	particles.scale_amount_max = maximum_scale
	particles.color = tint
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.2, 0.5, 0.8, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.65), Color.WHITE, Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)])
	particles.color_ramp = fade
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	particles.material = additive
	add_child(particles)
	emitters.append(particles)

func _fit_emitters() -> void:
	for particles in emitters:
		particles.position = size * 0.5
		particles.emission_rect_extents = size * 0.5
		particles.restart()
