extends ProgressBar

@export_enum("attack", "dodge") var ability := "attack"
var icon: Texture2D
var ready_flash := 0.0
var clock := 0.0
var was_ready := true

func _ready() -> void:
    show_percentage = false
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_theme_stylebox_override("background", StyleBoxEmpty.new())
    add_theme_stylebox_override("fill", StyleBoxEmpty.new())
    icon = load("res://sprites/hud/%s-icon.svg" % ability)
    value_changed.connect(_value_changed)
    was_ready = value >= max_value
    queue_redraw()

func _value_changed(_amount: float) -> void:
    var available := value >= max_value - 0.01
    if available and not was_ready:
        ready_flash = 0.45
    was_ready = available
    queue_redraw()

func _process(delta: float) -> void:
    clock += delta
    ready_flash = maxf(0, ready_flash - delta)
    queue_redraw()

func _draw() -> void:
    if icon == null:
        return
    var center := Vector2(size.x * 0.5, 29)
    var tint := Color("efc774") if ability == "attack" else Color("86dbcd")
    var ratio := clampf(value / maxf(1, max_value), 0, 1)
    var available := ratio >= 0.9999
    if available:
        var glow := 0.07 + 0.035 * sin(clock * 2.4) + ready_flash * 0.35
        for index in range(3):
            draw_circle(center, 28.0 + index * 3.0, Color(tint, glow / (index + 1)))
    draw_circle(center, 26, Color("10211f"))
    draw_arc(center, 25, 0, TAU, 48, Color("42534b"), 1.5, true)
    draw_arc(center, 25, -PI * 0.5, -PI * 0.5 + TAU * ratio, 48, Color(tint, 1 if available else 0.7), 2, true)
    var icon_rect := Rect2(center - Vector2(18, 18), Vector2(36, 36))
    draw_texture_rect(icon, icon_rect, false, Color("52615b"))
    if ratio > 0:
        var filled := Rect2(icon_rect.position + Vector2(0, icon_rect.size.y * (1-ratio)), Vector2(icon_rect.size.x, icon_rect.size.y * ratio))
        var region := Rect2(Vector2(0, icon.get_height() * (1-ratio)), Vector2(icon.get_width(), icon.get_height() * ratio))
        draw_texture_rect_region(icon, filled, region, tint)
    var key := "K" if ability == "attack" else "Shift"
    var font := get_theme_font("font")
    draw_string(font, Vector2(0, 77), key, HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, Color("f5e8c7"))
