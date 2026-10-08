extends CanvasLayer

var elapsed := 0.0
var roar_elapsed := -1.0
var screen: Control

func _ready() -> void:
    layer = 4
    screen = Control.new()
    screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(screen)
    screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    screen.draw.connect(_draw_screen)

func roar() -> void:
    roar_elapsed = 0.0

func _process(delta: float) -> void:
    elapsed += delta
    if roar_elapsed >= 0.0:
        roar_elapsed += delta
    screen.queue_redraw()

func _draw_screen() -> void:
    var bar_height := minf(elapsed / 0.5, 1.0) * 44.0
    screen.draw_rect(Rect2(0, 0, screen.size.x, bar_height), Color(0.025, 0.012, 0.005, 0.95))
    screen.draw_rect(Rect2(0, screen.size.y - bar_height, screen.size.x, bar_height), Color(0.025, 0.012, 0.005, 0.95))
    if roar_elapsed < 0.0:
        return
    var flash := maxf(0.0, 1.0 - roar_elapsed / 0.22)
    screen.draw_rect(Rect2(Vector2.ZERO, screen.size), Color(1, 0.55, 0.12, flash * 0.24))
    for i in range(32):
        var phase := fmod(roar_elapsed * (95.0 + i * 2.0) + i * 41.0, screen.size.y)
        var point := Vector2(fmod(i * 137.0, screen.size.x) + sin(elapsed * 3.0 + i) * 16.0, screen.size.y - phase)
        var alpha := sin(PI * phase / maxf(screen.size.y, 1.0)) * 0.65
        screen.draw_line(point, point + Vector2(-4, 9), Color(1, 0.45, 0.05, alpha * 0.5), 2.0, true)
        screen.draw_circle(point, 1.5 + i % 3, Color(1, 0.8, 0.3, alpha))
