extends Control

signal completed

const FRAME := preload("res://sprites/dialogo/Moldura de diálogo.png")
const HEADS := preload("res://sprites/dialogo/sprie sheet cabeças personagens.png")
const SPEAKER_ROWS := {"boitata": 0, "player": 1, "iara": 2, "cuca": 3, "vitoria": 4}
var text_label: Label
var portrait: TextureRect
var hint: Label
var pages: Array[String] = []
var page_index := 0
var elapsed := 0.0
var speaker := ""
var opened_at := 0
var reveal := 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    offset_left = 70
    offset_right = -70
    offset_top = -295
    offset_bottom = -45
    var frame := TextureRect.new()
    var atlas := AtlasTexture.new()
    atlas.atlas = FRAME
    atlas.region = Rect2(24, 94, 2124, 530)
    frame.texture = atlas
    frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(frame)
    portrait = TextureRect.new()
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait.position = Vector2(60, 60)
    portrait.size = Vector2(140, 140)
    add_child(portrait)
    text_label = Label.new()
    text_label.position = Vector2(260, 67)
    text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    text_label.add_theme_font_size_override("font_size", 24)
    add_child(text_label)
    hint = Label.new()
    hint.add_theme_font_size_override("font_size", 15)
    hint.text = "Enter / Espaço"
    add_child(hint)
    resized.connect(_layout)
    _layout()
    hide()

func _layout() -> void:
    if text_label == null:
        return
    text_label.size = Vector2(maxf(100, size.x - 320), 120)
    hint.position = Vector2(size.x - 230, size.y - 82)

func begin(character: String, _display_name: String, lines: Array) -> void:
    speaker = character
    pages.assign(lines)
    page_index = 0
    opened_at = Time.get_ticks_msec()
    _page()
    show()

func _page() -> void:
    text_label.text = pages[page_index]
    text_label.visible_characters = 0
    reveal = 0.0

func _process(delta: float) -> void:
    if not visible:
        return
    elapsed += delta
    reveal += delta * 38.0
    text_label.visible_characters = mini(text_label.get_total_character_count(), int(reveal))
    var speaking := text_label.visible_characters < text_label.get_total_character_count()
    hint.visible = not speaking
    if SPEAKER_ROWS.has(speaker):
        var column := 1 + int(elapsed * 7.0) % 2 if speaking else 0
        var cell_width := HEADS.get_width() / 4
        var cell_height := HEADS.get_height() / 5
        var cell := Rect2i(column * cell_width, int(SPEAKER_ROWS[speaker]) * cell_height, cell_width, cell_height)
        var atlas := AtlasTexture.new()
        atlas.atlas = HEADS
        atlas.region = Rect2(cell)
        atlas.filter_clip = true
        portrait.texture = atlas
    else:
        portrait.texture = null
    portrait.visible = portrait.texture != null

func advance() -> void:
    if text_label.visible_characters < text_label.get_total_character_count():
        reveal = float(text_label.get_total_character_count())
        text_label.visible_characters = text_label.get_total_character_count()
        return
    page_index += 1
    if page_index < pages.size():
        _page()
    else:
        hide()
        completed.emit()

func _unhandled_input(event: InputEvent) -> void:
    if visible and Time.get_ticks_msec() - opened_at > 200 and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_SPACE]:
        advance()
        get_viewport().set_input_as_handled()
