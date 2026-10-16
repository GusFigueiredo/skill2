extends SceneTree

func _initialize() -> void:
    call_deferred("preview")

func preview() -> void:
    root.size = Vector2i(1280, 720)
    var layer := CanvasLayer.new()
    root.add_child(layer)
    var background := ColorRect.new()
    background.color = Color("152d30")
    layer.add_child(background)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var frames = preload("res://scripts/VitoriaFrames.gd").build()
    for index in range(4):
        var sprite := AnimatedSprite2D.new()
        sprite.sprite_frames = frames
        sprite.position = Vector2(200 + index * 290, 265)
        sprite.offset = preload("res://scripts/VitoriaFrames.gd").grounded_offset(frames)
        sprite.play(["plant", "transform", "idle", "leaf"][index])
        layer.add_child(sprite)
    var box = preload("res://scripts/DialogueBox.gd").new()
    layer.add_child(box)
    box.begin("vitoria", "Vitória-Régia", ["Você está a salvo. A Cuca se esconde em uma caverna além deste rio."])
    box.advance()
    await create_timer(0.3).timeout
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://.validation/polish-vitoria-sheet-dialogue.png")
    quit()
