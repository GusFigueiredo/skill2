extends CanvasLayer

var elapsed := 0.0
var roar_elapsed := -1.0
var screen: Control
var cool_theme := false
var accent_strength := 0.0
var dismiss_progress := 0.0
var dismiss_tween: Tween
var title_progress := 0.0
var title_tween: Tween
var title_label: Label
var subtitle_label: Label
var title_scale_factor := -1.0

func _ready() -> void:
    layer = 4
    screen = Control.new()
    screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(screen)
    screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    screen.draw.connect(_draw_screen)
    title_label = _make_title_label(38, Color("f9e5bf"))
    subtitle_label = _make_title_label(18, Color("e7b76e"))

func _make_title_label(font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.add_theme_font_override("font", preload("res://fonts/PirataOne-Regular.ttf"))
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
    label.add_theme_constant_override("shadow_offset_y", 2)
    label.modulate.a = 0.0
    screen.add_child(label)
    return label

# Optional, so the same overlay also works for conversations and the rescue scene.
func set_title(title: String, subtitle: String = "") -> void:
    title_label.text = title
    subtitle_label.text = subtitle
    subtitle_label.add_theme_color_override("font_color", Color("a2e6ed") if cool_theme else Color("e7b76e"))
    if title_tween != null and title_tween.is_valid():
        title_tween.kill()
    title_progress = 0.0
    title_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    title_tween.tween_property(self, "title_progress", 1.0, 0.65)

func roar() -> void:
    roar_elapsed = 0.0

# The owner keeps control of the cutscene timeline and frees this overlay afterward.
func dismiss(seconds: float = 0.5) -> void:
    if dismiss_tween != null and dismiss_tween.is_valid():
        dismiss_tween.kill()
    dismiss_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    dismiss_tween.tween_property(self, "dismiss_progress", 1.0, maxf(seconds, 0.001))

func _process(delta: float) -> void:
    elapsed += delta
    if roar_elapsed >= 0.0:
        roar_elapsed += delta
    var scale_factor := clampf(screen.size.y / 720.0, 0.65, 1.5)
    var visibility := smoothstep(0.0, 0.6, elapsed) * (1.0 - dismiss_progress)
    var left := 52.0 * scale_factor - (1.0 - title_progress) * 16.0 * scale_factor
    title_label.position = Vector2(left, screen.size.y - 140.0 * scale_factor)
    subtitle_label.position = Vector2(left + 1.0, screen.size.y - 90.0 * scale_factor)
    if not is_equal_approx(title_scale_factor, scale_factor):
        title_scale_factor = scale_factor
        title_label.add_theme_font_size_override("font_size", roundi(38.0 * scale_factor))
        subtitle_label.add_theme_font_size_override("font_size", roundi(18.0 * scale_factor))
    title_label.modulate.a = visibility * title_progress
    subtitle_label.modulate.a = visibility * title_progress * 0.9
    screen.queue_redraw()

func _draw_screen() -> void:
    var opening := smoothstep(0.0, 0.6, elapsed)
    var visibility := opening * (1.0 - dismiss_progress)
    if visibility <= 0.0 or screen.size.x <= 0.0 or screen.size.y <= 0.0:
        return
    var bar_height := visibility * screen.size.y * (44.0 / 720.0)
    var dark := Color(0.009, 0.023, 0.032, 0.96) if cool_theme else Color(0.025, 0.012, 0.005, 0.96)
    var accent := Color(0.35, 0.81, 0.87) if cool_theme else Color(1.0, 0.61, 0.26)
    dark.a *= visibility
    screen.draw_rect(Rect2(0, 0, screen.size.x, bar_height), dark)
    screen.draw_rect(Rect2(0, screen.size.y - bar_height, screen.size.x, bar_height), dark)
    # Feather the inner edges into the picture instead of cutting abruptly to black.
    for step in range(10):
        var fade := pow(1.0 - float(step) / 10.0, 2.0) * 0.16 * visibility
        var feather := Color(dark.r, dark.g, dark.b, fade)
        screen.draw_rect(Rect2(0, bar_height + step * 2.0, screen.size.x, 2.0), feather)
        screen.draw_rect(Rect2(0, screen.size.y - bar_height - (step + 1) * 2.0, screen.size.x, 2.0), feather)
    var seam := Color(accent.r, accent.g, accent.b, 0.10 * visibility)
    screen.draw_line(Vector2(0, bar_height), Vector2(screen.size.x, bar_height), seam, 1.0)
    screen.draw_line(Vector2(0, screen.size.y - bar_height), Vector2(screen.size.x, screen.size.y - bar_height), seam, 1.0)

    # A shallow edge vignette draws the eye to the actors without blurring the art.
    for step in range(12):
        var shade_alpha := pow(1.0 - float(step) / 12.0, 2.0) * 0.035 * visibility
        var shade := Color(dark.r, dark.g, dark.b, shade_alpha)
        var inset := screen.size.x * 0.013 * step
        screen.draw_rect(Rect2(inset, bar_height, screen.size.x * 0.013, screen.size.y - bar_height * 2.0), shade)
        screen.draw_rect(Rect2(screen.size.x - inset - screen.size.x * 0.013, bar_height, screen.size.x * 0.013, screen.size.y - bar_height * 2.0), shade)

    if not title_label.text.is_empty():
        var title_scale := clampf(screen.size.y / 720.0, 0.65, 1.5)
        var rule_y := screen.size.y - 96.0 * title_scale
        var rule_alpha := visibility * title_progress * 0.42
        screen.draw_line(Vector2(52.0 * title_scale, rule_y), Vector2((52.0 + 140.0 * title_progress) * title_scale, rule_y), Color(accent.r, accent.g, accent.b, rule_alpha), 1.0)

    # Low contrast atmosphere leaves the characters and their pixel art crisp.
    if cool_theme:
        screen.draw_rect(Rect2(Vector2.ZERO, screen.size), Color(0.08, 0.30, 0.42, (0.022 + accent_strength * 0.024) * visibility))
        _draw_water_glints(visibility)
    else:
        screen.draw_rect(Rect2(Vector2.ZERO, screen.size), Color(0.46, 0.16, 0.035, (0.012 + accent_strength * 0.028) * visibility))
        _draw_fire_glints(visibility)
    if roar_elapsed < 0.0:
        return
    var flash := pow(maxf(0.0, 1.0 - roar_elapsed / 0.38), 2.0)
    screen.draw_rect(Rect2(Vector2.ZERO, screen.size), Color(accent.r, accent.g, accent.b, flash * 0.10 * visibility))
    var embers := (1.0 - smoothstep(1.0, 2.8, roar_elapsed)) * visibility
    for i in range(32):
        var phase := fmod(roar_elapsed * (95.0 + i * 2.0) + i * 41.0, screen.size.y)
        var point := Vector2(fmod(i * 137.0, screen.size.x) + sin(elapsed * 3.0 + i) * 16.0, screen.size.y - phase).round()
        var alpha := sin(PI * phase / maxf(screen.size.y, 1.0)) * 0.55 * embers
        screen.draw_line(point, point + Vector2(-3, 6), Color(accent.r, accent.g, accent.b, alpha * 0.3), 1.0)
        screen.draw_circle(point, 4.0 + i % 3, Color(accent.r, accent.g, accent.b, alpha * 0.09))
        var core := Color(0.75, 0.97, 1.0, alpha) if cool_theme else Color(1.0, 0.84, 0.43, alpha)
        screen.draw_rect(Rect2(point, Vector2.ONE * (2.0 + i % 2)), core)

func _draw_fire_glints(visibility: float) -> void:
    for i in range(14):
        var phase := fmod(elapsed * (24.0 + i * 0.8) + i * 47.0, screen.size.y)
        var inset := 16.0 + fmod(i * 71.0, screen.size.x * 0.15)
        var x := inset if i % 2 == 0 else screen.size.x - inset
        var point := Vector2(x + sin(elapsed * 1.2 + i) * 9.0, screen.size.y - phase).round()
        var alpha := sin(PI * phase / screen.size.y) * (0.12 + accent_strength * 0.12) * visibility
        screen.draw_circle(point, 5.0, Color(1.0, 0.43, 0.12, alpha * 0.1))
        screen.draw_rect(Rect2(point, Vector2(2, 2)), Color(1.0, 0.72, 0.34, alpha))

func _draw_water_glints(visibility: float) -> void:
    for i in range(16):
        var phase := fmod(elapsed * (18.0 + i * 0.6) + i * 37.0, screen.size.y)
        var side := -1.0 if i % 2 == 0 else 1.0
        var inset := 18.0 + fmod(i * 61.0, screen.size.x * 0.16)
        var x := inset if side < 0.0 else screen.size.x - inset
        var point := Vector2(x + sin(elapsed * 0.7 + i) * 12.0, screen.size.y - phase)
        var alpha := sin(PI * phase / screen.size.y) * (0.12 + accent_strength * 0.12) * visibility
        screen.draw_circle(point, 5.0, Color(0.22, 0.77, 0.85, alpha * 0.12))
        screen.draw_circle(point, 1.2, Color(0.68, 0.96, 1.0, alpha))
