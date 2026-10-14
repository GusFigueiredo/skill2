extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func run_checks() -> void:
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
    await process_frame
    box.begin("vitoria", "Vitória-Régia", ["Primeira fala.", "Segunda fala."])
    box._process(0.1)
    assert(box.text_label.visible_characters > 0 and box.text_label.visible_characters < box.text_label.get_total_character_count())
    assert(box.portrait.texture != null)
    assert(box.portrait.texture.atlas == box.HEADS, "Vitoria must use the new fifth portrait row")
    assert(box.get_children().filter(func(child): return child is Label).size() == 2, "Dialogue must only contain text and the advance hint, without a speaker name")
    box.advance()
    assert(box.visible and box.page_index == 0, "First press must reveal, not skip, the page")
    box.advance()
    assert(box.page_index == 1 and box.text_label.visible_characters == 0)
    box.advance()
    box.advance()
    assert(not box.visible)
    for speaker in ["boitata", "player", "iara", "cuca", "vitoria"]:
        box.begin(speaker, speaker, ["Teste."])
        box._process(0.01)
        assert(box.portrait.texture.atlas == box.HEADS)
    print("PASS: Vitoria's four animations, nonempty poses, feet alignment, dialogue typewriter, paging and portraits")
    quit()
