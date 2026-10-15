extends Control

signal completed

const FRAME := preload("res://sprites/dialogo/Moldura de diálogo.png")
const PORTRAITS := preload("res://scripts/DialoguePortraits.gd")
const FRAME_REGION := Rect2(24, 94, 2124, 530)
const FRAME_LEFT_WIDTH := 470.0
const FRAME_RIGHT_WIDTH := 132.0
const PORTRAIT_PANEL_EXTRA := 28.0
const FONT_SIZE := 34
const BOX_HEIGHT := 300.0
const PORTRAIT_SIZE := Vector2(248, 232)
const MAX_TEXT_LINES := 3
const CHARACTERS_PER_SECOND := 38.0
const BOTTOM_MARGIN := 28.0

var text_label: Label
var portrait: TextureRect
var hint: Label
var page_hint: Label
var pages: Array[String] = []
var page_index := 0
var elapsed := 0.0
var speaker := ""
var opened_at := 0
var reveal := 0.0
var expression_index := 0
var portrait_textures: Dictionary = {}
var _character_wait := 0.0
var _opening_tween: Tween
var _portrait_tween: Tween
var _portrait_origin := Vector2.ZERO
var _text_tween: Tween

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    offset_left = 40
    offset_right = -40
    offset_top = -BOX_HEIGHT - BOTTOM_MARGIN
    offset_bottom = -BOTTOM_MARGIN
    portrait_textures = PORTRAITS.build()
    portrait = TextureRect.new()
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait.size = PORTRAIT_SIZE
    add_child(portrait)
    text_label = Label.new()
    text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    text_label.add_theme_font_size_override("font_size", FONT_SIZE)
    text_label.add_theme_color_override("font_color", Color("fff0d1"))
    text_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
    text_label.add_theme_constant_override("shadow_offset_x", 1)
    text_label.add_theme_constant_override("shadow_offset_y", 2)
    text_label.add_theme_constant_override("line_spacing", 3)
    add_child(text_label)
    hint = Label.new()
    hint.add_theme_font_size_override("font_size", 22)
    hint.add_theme_color_override("font_color", Color("d1c3a8"))
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    hint.text = "Enter / Espaço"
    add_child(hint)
    page_hint = Label.new()
    page_hint.add_theme_font_size_override("font_size", 22)
    page_hint.add_theme_color_override("font_color", Color("b8a283"))
    add_child(page_hint)
    resized.connect(_layout)
    _layout()
    hide()

func _layout() -> void:
    if text_label == null:
        return
    var art_scale := BOX_HEIGHT / FRAME_REGION.size.y
    _portrait_origin = Vector2(64, 75)
    portrait.position = _portrait_origin
    text_label.position = Vector2(FRAME_LEFT_WIDTH * art_scale + PORTRAIT_PANEL_EXTRA + 16, 70)
    text_label.size = Vector2(maxf(100, size.x - text_label.position.x - 60), 160)
    hint.position = Vector2(size.x - 356, 230)
    hint.size = Vector2(206, 32)
    page_hint.position = Vector2(text_label.position.x, 230)
    page_hint.size = Vector2(180, 32)
    queue_redraw()

func _draw() -> void:
    # Widen the portrait's middle independently so the larger head fits. The
    # carved corners and vertical divider retain the artwork's original scale.
    var art_scale := BOX_HEIGHT / FRAME_REGION.size.y
    var left_width := FRAME_LEFT_WIDTH * art_scale + PORTRAIT_PANEL_EXTRA
    var right_width := FRAME_RIGHT_WIDTH * art_scale
    var portrait_cuts := [0.0, 136.0, 404.0, FRAME_LEFT_WIDTH]
    var destination_x := 0.0
    for index in range(3):
        var source_width: float = portrait_cuts[index + 1] - portrait_cuts[index]
        var destination_width := source_width * art_scale + (PORTRAIT_PANEL_EXTRA if index == 1 else 0.0)
        draw_texture_rect_region(FRAME, Rect2(destination_x, 0, destination_width, BOX_HEIGHT), Rect2(FRAME_REGION.position + Vector2(portrait_cuts[index], 0), Vector2(source_width, FRAME_REGION.size.y)))
        destination_x += destination_width
    draw_texture_rect_region(FRAME, Rect2(left_width, 0, maxf(0, size.x - left_width - right_width), BOX_HEIGHT), Rect2(FRAME_REGION.position + Vector2(FRAME_LEFT_WIDTH, 0), Vector2(FRAME_REGION.size.x - FRAME_LEFT_WIDTH - FRAME_RIGHT_WIDTH, FRAME_REGION.size.y)))
    draw_texture_rect_region(FRAME, Rect2(size.x - right_width, 0, right_width, BOX_HEIGHT), Rect2(FRAME_REGION.position + Vector2(FRAME_REGION.size.x - FRAME_RIGHT_WIDTH, 0), Vector2(FRAME_RIGHT_WIDTH, FRAME_REGION.size.y)))

func begin(character: String, _display_name: String, lines: Array) -> void:
    var was_visible := visible
    var changed_speaker := speaker != character
    speaker = character
    pages.clear()
    for line: String in lines:
        pages.append_array(_paginate(line))
    if pages.is_empty():
        pages.append("")
    page_index = 0
    elapsed = 0.0
    opened_at = Time.get_ticks_msec()
    _page()
    show()
    if not was_visible:
        if is_instance_valid(_opening_tween):
            _opening_tween.kill()
        modulate.a = 0.0
        offset_top = -BOX_HEIGHT - BOTTOM_MARGIN + 18
        offset_bottom = -BOTTOM_MARGIN + 18
        _opening_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
        _opening_tween.tween_property(self, "modulate:a", 1.0, 0.26)
        _opening_tween.parallel().tween_property(self, "offset_top", -BOX_HEIGHT - BOTTOM_MARGIN, 0.32)
        _opening_tween.parallel().tween_property(self, "offset_bottom", -BOTTOM_MARGIN, 0.32)
    if changed_speaker or not was_visible:
        _enter_portrait()

func _paginate(line: String) -> Array[String]:
    # Measure with the Label's actual font and wrap settings, preserving every
    # character (including spaces) when a long speech needs another page.
    var result: Array[String] = []
    var cursor := 0
    while cursor < line.length():
        var best_end := cursor
        var probe := cursor
        while probe < line.length():
            var word_end := line.find(" ", probe)
            if word_end == -1:
                word_end = line.length()
            else:
                word_end += 1
            if _line_count(line.substr(cursor, word_end - cursor)) > MAX_TEXT_LINES:
                break
            best_end = word_end
            probe = word_end
        if best_end == cursor:
            # A single unusually long word can wrap; split it rather than clip.
            best_end = cursor + 1
            while best_end < line.length():
                if _line_count(line.substr(cursor, best_end - cursor + 1)) > MAX_TEXT_LINES:
                    break
                best_end += 1
        result.append(line.substr(cursor, best_end - cursor))
        cursor = best_end
    if result.is_empty():
        result.append("")
    return result

func _line_count(text: String) -> int:
    var paragraph := TextParagraph.new()
    paragraph.width = text_label.size.x
    paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
    paragraph.add_string(text, text_label.get_theme_font("font"), FONT_SIZE)
    return paragraph.get_line_count()

func _page() -> void:
    text_label.text = pages[page_index]
    text_label.visible_characters = 0
    reveal = 0.0
    _character_wait = 0.0
    hint.hide()
    page_hint.text = "%d / %d" % [page_index + 1, pages.size()] if pages.size() > 1 else ""
    page_hint.hide()
    _set_expression(0)
    if is_instance_valid(_text_tween):
        _text_tween.kill()
    text_label.modulate.a = 0.45
    _text_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    _text_tween.tween_property(text_label, "modulate:a", 1.0, 0.16)

func _enter_portrait() -> void:
    if is_instance_valid(_portrait_tween):
        _portrait_tween.kill()
    # Animate alpha through self_modulate, preserving Vitória's mystery tint.
    portrait.self_modulate.a = 0.0
    portrait.position = _portrait_origin + Vector2(-12, 0)
    _portrait_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    _portrait_tween.tween_property(portrait, "position", _portrait_origin, 0.28)
    _portrait_tween.parallel().tween_property(portrait, "self_modulate:a", 1.0, 0.2)

func _process(delta: float) -> void:
    if not visible:
        return
    elapsed += delta
    var total := text_label.get_total_character_count()
    if text_label.visible_characters < total:
        _character_wait -= delta
        while _character_wait <= 0.0 and text_label.visible_characters < total:
            text_label.visible_characters += 1
            reveal = float(text_label.visible_characters)
            var index := mini(text_label.visible_characters - 1, text_label.text.length() - 1)
            var character := text_label.text.substr(index, 1)
            _character_wait += 1.0 / CHARACTERS_PER_SECOND
            if character in [".", "!", "?", "…"]:
                _character_wait += 0.15
            elif character in [",", ";", ":"]:
                _character_wait += 0.075
    var speaking := text_label.visible_characters < total
    hint.visible = not speaking
    page_hint.visible = not speaking and pages.size() > 1
    hint.modulate.a = 0.82 + sin(elapsed * 3.0) * 0.12
    _set_expression(1 + int(elapsed * 7.0) % 2 if speaking and _character_wait < 0.08 else 0)

func _set_expression(index: int) -> void:
    expression_index = index
    portrait.texture = portrait_textures[speaker][index] if portrait_textures.has(speaker) else null
    portrait.visible = portrait.texture != null

func advance() -> void:
    if not visible:
        return
    if text_label.visible_characters < text_label.get_total_character_count():
        reveal = float(text_label.get_total_character_count())
        text_label.visible_characters = text_label.get_total_character_count()
        hint.show()
        page_hint.visible = pages.size() > 1
        _set_expression(0)
        return
    page_index += 1
    if page_index < pages.size():
        _page()
    else:
        # Keep the box open when the completed callback immediately starts the
        # next speaker. This avoids flashing/reopening between conversation turns.
        completed.emit()
        if page_index >= pages.size():
            hide()

func _unhandled_input(event: InputEvent) -> void:
    if visible and Time.get_ticks_msec() - opened_at > 200 and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_SPACE]:
        advance()
        get_viewport().set_input_as_handled()
