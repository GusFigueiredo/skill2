extends Node2D

# World-space detail lives between the scenery and the actors. All movement is
# deterministic and inherits the level's pause state.
var elapsed: float = 0.0
var warm_ruins := true

func _ready() -> void:
	z_index = -1
	warm_ruins = get_parent().stage_index == 0

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var inverse := get_canvas_transform().affine_inverse()
	var view := get_viewport_rect()
	var left := (inverse * view.position).x - 100.0
	var right := (inverse * view.end).x + 100.0
	var glow_color := Color(1.0, 0.79, 0.38) if warm_ruins else Color(0.79, 0.88, 0.42)
	# Sparse clusters have independent drift, height and breathing speed. They
	# never march in rows or wrap across the screen when the camera pans.
	for index in range(74):
		var seed := float(index) * 2.39996
		var x := 52.0 + fposmod(index * 173.71, 3800.0) + sin(elapsed * (0.12 + index % 3 * 0.027) + seed) * 16.0
		if x < left or x > right:
			continue
		var y := 245.0 + fposmod(index * 67.37, 225.0) + sin(elapsed * 0.29 + seed * 1.7) * 9.0
		var pulse := pow(0.5 + 0.5 * sin(elapsed * (0.76 + index % 5 * 0.11) + seed), 2.0)
		var opacity := 0.04 + pulse * (0.35 if warm_ruins else 0.39)
		var point := Vector2(x, y)
		draw_circle(point, 4.5, Color(glow_color, opacity * 0.028))
		draw_circle(point, 2.5, Color(glow_color, opacity * 0.065))
		draw_rect(Rect2(point.floor(), Vector2.ONE), Color(glow_color, opacity))
	# Broad, feathered light on the rear verge suggests sun between the trees.
	# The path's source pixels and the combat silhouettes remain unobscured.
	for index in range(10):
		var x := 150.0 + index * 397.3 + sin(float(index) * 2.41) * 55.0
		if x + 90.0 < left or x - 90.0 > right:
			continue
		var center := Vector2(x, 318.0 + sin(float(index) * 1.7) * 13.0)
		var breath := 0.8 + sin(elapsed * 0.33 + index * 1.9) * 0.2
		draw_set_transform(center, -0.12, Vector2(1.0, 0.22))
		for ring in range(8, 0, -1):
			draw_circle(Vector2.ZERO, 10.0 * ring, Color(glow_color, 0.0035 * breath))
		draw_set_transform(Vector2.ZERO)
	# A handful of tumbling leaves stays above the foreground action.
	for index in range(21):
		var seed := float(index) * 1.717
		var x := fposmod(index * 247.9 + elapsed * (2.1 + index % 4 * 0.45), 3900.0) - 40.0
		if x < left or x > right:
			continue
		var y := 192.0 + fposmod(index * 93.7 + elapsed * (2.7 + index % 3 * 0.5), 166.0)
		var point := Vector2(x + sin(elapsed * 0.53 + seed) * 11.0, y)
		var tilt := sin(elapsed * 0.8 + seed)
		var leaf_color := Color(0.58, 0.51, 0.27, 0.37) if warm_ruins else Color(0.39, 0.53, 0.29, 0.35)
		draw_line(point, point + Vector2(2.3, tilt * 1.6), leaf_color, 1.0)
