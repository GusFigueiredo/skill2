extends CanvasLayer

signal finished
var elapsed := 0.0
var screen: Control
var title: Label
const DURATION := 0.75

func _ready() -> void:
    layer = 5
    screen = Control.new()
    screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(screen)
    screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    screen.draw.connect(_draw_screen)
    title = Label.new()
    title.text = "FASE CONCLU\u00cdDA"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 42)
    title.add_theme_color_override("font_color", Color("ffe5a6"))
    title.add_theme_color_override("font_outline_color", Color("21190f"))
    title.add_theme_constant_override("outline_size", 4)
    title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    screen.add_child(title)
    var sound := AudioStreamPlayer.new()
    sound.stream = load("res://soundeffect/Feedback/victory.wav")
    sound.volume_db = -14
    sound.process_mode = Node.PROCESS_MODE_ALWAYS
    get_parent().add_child(sound)
    sound.finished.connect(sound.queue_free)
    sound.play()

func _process(delta: float) -> void:
    elapsed += delta
    title.position = Vector2(0, screen.size.y * 0.28 - 22)
    title.size.x = screen.size.x
    screen.modulate.a = minf(elapsed / 0.12, clampf((DURATION - elapsed) / 0.18, 0, 1))
    screen.queue_redraw()
    if elapsed >= DURATION:
        finished.emit()
        queue_free()

func _draw_screen() -> void:
    var center := Vector2(screen.size.x * 0.5, screen.size.y * 0.28)
    for index in range(16):
        var heading := Vector2.from_angle(index * 2.399)
        var point := center + heading * (60 + elapsed * 120)
        screen.draw_circle(point, 1.5, Color(1, 0.78, 0.28, 0.5))
    screen.draw_line(center + Vector2(-150, 34), center + Vector2(150, 34), Color(1, 0.8, 0.4, 0.6), 1, true)
