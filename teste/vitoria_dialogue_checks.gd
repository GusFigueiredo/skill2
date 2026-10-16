extends SceneTree

var completed_blocks := 0

func _initialize() -> void:
    call_deferred("run_checks")

func run_checks() -> void:
    create_timer(20.0, true).timeout.connect(func(): quit(1))
    root.size = Vector2i(1280, 720)
    var frames = preload("res://scripts/VitoriaFrames.gd").build()
    var expected_frames := {"plant": 1, "leaf": 1, "transform": 5, "idle": 6}
    var frame_size: Vector2 = frames.get_frame_texture("plant", 0).get_size()
    for animation in expected_frames:
        assert(frames.get_frame_count(animation) == expected_frames[animation], "Use every supplied pose from the updated sheet")
        for index in frames.get_frame_count(animation):
            var texture = frames.get_frame_texture(animation, index)
            var opaque: Rect2i = texture.get_image().get_used_rect()
            assert(opaque.size.x > 20 and opaque.size.y > 20, "Each pose must contain actual visible artwork from its row")
            assert(texture.get_size() == frame_size, "Poses must share the same feet-aligned canvas")
    assert(not frames.has_animation("dash"), "The updated sheet has no dash artwork: its blank third row must never become an animation")
    var layer := CanvasLayer.new()
    root.add_child(layer)
    var box = preload("res://scripts/DialogueBox.gd").new()
    layer.add_child(box)
    box.completed.connect(func(): completed_blocks += 1)
    await process_frame
    await process_frame
    box.begin("vitoria", "Vitória-Régia", ["Primeira fala.", "Segunda fala."])
    box._process(0.1)
    assert(box.text_label.visible_characters > 0 and box.text_label.visible_characters < box.text_label.get_total_character_count())
    assert(box.portrait.texture != null)
    assert(box.text_label.get_theme_font_size("font_size") == 26, "Reduce the shared dialogue text by 25%, rounded to whole pixels")
    assert(box.size.is_equal_approx(Vector2(900, 225)), "The dialogue frame must be 25% smaller and horizontally centered")
    assert(is_equal_approx(box.position.x, 190.0), "The reduced dialogue frame stays centered in a 1280px viewport")
    assert(box.portrait.size.x <= 186 and box.portrait.size.y <= 174, "The portrait must shrink with the box and fit its carved window")
    assert(box.text_label.get_rect().end.y < box.hint.position.y, "Dialogue text cannot overlap the advance hint")
    assert(box.page_hint.get_rect().end.x < box.hint.position.x, "The page count cannot overlap the advance hint")
    for element in [box.portrait, box.text_label, box.hint, box.page_hint]:
        assert(Rect2(Vector2.ZERO, box.size).encloses(element.get_rect()), "Every reduced dialogue element stays inside the frame")
    for child in box.get_children():
        assert(not (child is Label and child.text == "Vitória-Régia"), "A speaker name must not appear")
    box.advance()
    assert(box.visible and box.page_index == 0, "First press must reveal, not skip, the page")
    box.advance()
    assert(box.page_index == 1 and box.text_label.visible_characters == 0)
    await finish_block(box)
    assert(not box.visible and completed_blocks == 1)
    var neutral_portraits: Array[Texture2D] = []
    for character in ["boitata", "player", "cuca", "vitoria"]:
        box.begin(character, character, ["Teste de retrato."])
        box._process(0.03)
        assert(box.portrait.visible and box.portrait.texture != null, "The new sheet must supply all four characters")
        var talking_texture: Texture2D = box.portrait.texture
        box.advance()
        box._process(0.0)
        assert(box.portrait.texture != talking_texture, "Revealing the page must return to the neutral expression")
        assert(not neutral_portraits.has(box.portrait.texture), "Each character must use their own row")
        neutral_portraits.append(box.portrait.texture)
        await finish_block(box)
    box.begin("iara", "Iara", ["Teste."])
    box._process(0.01)
    assert(not box.portrait.visible, "An absent Iara row must not display Cuca's portrait")
    await finish_block(box)
    box.portrait.modulate = Color(0.08, 0.08, 0.08, 1.0)
    box.begin("vitoria", "", ["Ela pode dominar o canto das águas. Mas não toda a vida que existe nelas."])
    box._process(0.2)
    assert(box.portrait.modulate == Color(0.08, 0.08, 0.08, 1.0), "The mysterious portrait must stay dark while its mouth changes")
    await finish_block(box)
    box.portrait.modulate = Color.WHITE
    var opening_turn: String = preload("res://scripts/BoitataDialogue.gd").LINES[0][1]
    var long_turn := opening_turn + " " + opening_turn + " " + opening_turn
    box.begin("boitata", "", [long_turn])
    assert("".join(box.pages) == long_turn, "Pagination must preserve the full speech without losing words")
    assert(box.pages.size() > 1, "A long speech must continue on another page at the smaller font size")
    var pages_checked := 0
    while box.visible:
        box.advance()
        await process_frame
        if pages_checked <= box.page_index:
            assert(box.text_label.get_line_count() <= box.MAX_TEXT_LINES, "Every page must fit inside the text region")
            assert(box.text_label.get_minimum_size().y <= box.text_label.size.y, "The smaller font must fit vertically without clipping")
            assert(box.page_hint.text == "%d / %d" % [box.page_index + 1, box.pages.size()], "Long speeches must show the current page")
            pages_checked = box.page_index + 1
        box.advance()
        await create_timer(0.03).timeout
    assert(pages_checked > 1, "All automatically split pages must be readable before the block completes")
    print("PASS: updated Vitoria sheet, six idle poses, no blank dash row, 25% smaller centered dialogue and aligned elements, complete unclipped pagination and mysterious portrait")
    quit()

func finish_block(box: Control) -> void:
    var advances := 0
    while box.visible and advances < 40:
        box.advance()
        advances += 1
        await create_timer(0.03).timeout
    assert(not box.visible, "The dialogue must complete after all pages have been advanced")
