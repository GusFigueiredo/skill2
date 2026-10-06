extends Node2D

# A deterministic, purely visual layer behind the actors.
var elapsed: float = 0.0

func _ready() -> void:
	z_index = -1

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	for index in range(90):
		var phase := float(index) * 2.399
		var x := fposmod(float(index) * 137.0 + elapsed * (4.0 + index % 4), 3800.0)
		var y := 275.0 + sin(phase + elapsed * 0.35) * 42.0 + float(index % 7) * 14.0
		var alpha := 0.12 + 0.20 * (0.5 + 0.5 * sin(elapsed * 1.6 + phase))
		draw_circle(Vector2(x, y), 1.2, Color(1.0, 0.78, 0.35, alpha))
	# Warm pools of light along the upper edge of the road.
	for x in range(160, 3800, 480):
		for ring in range(7, 0, -1):
			draw_set_transform(Vector2(x, 330), 0.0, Vector2(1.0, 0.32))
			draw_circle(Vector2.ZERO, ring * 12.0, Color(1.0, 0.65, 0.26, 0.012))
	draw_set_transform(Vector2.ZERO)
