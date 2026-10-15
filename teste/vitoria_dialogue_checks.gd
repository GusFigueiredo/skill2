extends SceneTree

var completed_blocks := 0

func _initialize() -> void:
    call_deferred("run_checks")

func run_checks() -> void:
    create_timer(20.0, true).timeout.connect(func(): quit(1))
    root.size = Vector2i(1280, 720)
    var frames = preload("res://scripts/VitoriaFrames.gd").build()
    for animation in {"plant": 1, "transform": 5, "idle": 5, "dash": 5}:
        assert(frames.get_frame_count(animation) == {"plant": 1, "transform": 5, "idle": 5, "dash": 5}[animation])
        for index in frames.get_frame_count(animation):
            var texture = frames.get_frame_texture(animation, index)
            assert(texture.region.size.x > 0 and texture.region.size.y > 0, "Each pose must contain visible pixels")
            assert(texture.get_size() == Vector2(300, 270), "Poses must share the same feet alignment")
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
    assert(box.text_label.get_theme_font_size("font_size") == 34, "Dialogue text must be 15% smaller")
    assert(is_equal_approx(box.size.y, 320.0), "The dialogue frame must be 15% shorter")
    assert(box.portrait.size.x >= 248 and box.portrait.size.y >= 232, "The new portraits must be clearly larger than the previous 196x184 area")
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
    print("PASS: Vitoria animations, 34px dialogue in a 320px frame with 248x232 portraits, full unclipped paginated speeches, page hints, typewriter/advance, four portrait rows and dark mystery portrait")
    quit()

func finish_block(box: Control) -> void:
    var advances := 0
    while box.visible and advances < 40:
        box.advance()
        advances += 1
        await create_timer(0.03).timeout
    assert(not box.visible, "The dialogue must complete after all pages have been advanced")
