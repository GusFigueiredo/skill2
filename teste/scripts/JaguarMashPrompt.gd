extends Control

const SHEET := preload("res://sprites/hud/Ícones Pixelados de Teclas K.png")
const ICON_SIZE := Vector2(148, 142)
const PROMPT_SIZE := Vector2(166, 170)
const PRESS_DROP := 12.0

static var cached_textures: Array[Texture2D] = []
var progress_ratio := 0.0
var danger_ratio := 0.0
var flash_time := 0.0
var clock := 0.0
var press_depth := 0.0
var icon: TextureRect
var normal_texture: Texture2D
var pressed_texture: Texture2D

func _ready() -> void:
    name = "JaguarMashPrompt"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    size = PROMPT_SIZE
    pivot_offset = size * 0.5
    if cached_textures.is_empty():
        # Remove only the exterior black backdrop; keep the key's dark detail.
        cached_textures.append(_key_texture(Rect2i(261, 51, 740, 566)))
        cached_textures.append(_key_texture(Rect2i(1111, 90, 736, 527)))
    normal_texture = cached_textures[0]
    pressed_texture = cached_textures[1]
    icon = TextureRect.new()
    icon.size = ICON_SIZE
    icon.pivot_offset = ICON_SIZE * 0.5
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(icon)
    hide()
    _refresh_visuals()

func flash_press() -> void:
    flash_time = 0.07
    press_depth = 1.0
    _refresh_visuals()

func _process(delta: float) -> void:
    if not is_visible_in_tree():
        return
    clock += delta
    flash_time = maxf(0.0, flash_time - delta)
    var down := flash_time > 0.0 or Input.is_key_pressed(KEY_K) or Input.is_physical_key_pressed(KEY_K)
    press_depth = move_toward(press_depth, 1.0 if down else 0.0, delta * 18.0)
    _refresh_visuals()

func _refresh_visuals() -> void:
    if not is_instance_valid(icon):
        return
    var danger := clampf(danger_ratio, 0.0, 1.0)
    var beat := sin(clock * (6.5 + danger * 4.0))
    var down := flash_time > 0.0 or Input.is_key_pressed(KEY_K) or Input.is_physical_key_pressed(KEY_K)
    var depth := maxf(press_depth, 1.0 if down else 0.0)
    var rest := 1.0 - depth
    var pulse := 1.0 + beat * (0.045 + progress_ratio * 0.012)
    icon.texture = pressed_texture if down else normal_texture
    icon.position = (size - ICON_SIZE) * 0.5 + Vector2(
        sin(clock * 9.0) * (1.5 + danger) * rest,
        sin(clock * 5.0) * 3.0 * rest + PRESS_DROP * depth)
    icon.scale = Vector2(lerpf(pulse, 0.97, depth), lerpf(pulse, 0.84, depth))
    icon.rotation = sin(clock * 8.0) * 0.035 * rest
    icon.modulate = Color.WHITE.lerp(Color(1.0, 0.78, 0.55), danger * 0.28 * rest)

func _key_texture(region: Rect2i) -> ImageTexture:
    var image := SHEET.get_image().get_region(region)
    image.convert(Image.FORMAT_RGBA8)
    var width := image.get_width()
    var height := image.get_height()
    var visited := PackedByteArray()
    visited.resize(width * height)
    var pending := PackedInt32Array()
    for x in range(width):
        pending.append(x)
        pending.append((height - 1) * width + x)
    for y in range(1, height - 1):
        pending.append(y * width)
        pending.append(y * width + width - 1)
    var head := 0
    while head < pending.size():
        var index := pending[head]
        head += 1
        if visited[index] != 0:
            continue
        visited[index] = 1
        var x := index % width
        var y := index / width
        var pixel := image.get_pixel(x, y)
        if maxf(pixel.r, maxf(pixel.g, pixel.b)) > 0.075:
            continue
        image.set_pixel(x, y, Color.TRANSPARENT)
        if x > 0:
            pending.append(index - 1)
        if x + 1 < width:
            pending.append(index + 1)
        if y > 0:
            pending.append(index - width)
        if y + 1 < height:
            pending.append(index + width)
    return ImageTexture.create_from_image(image)
