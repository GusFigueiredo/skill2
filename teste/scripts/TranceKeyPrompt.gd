extends Control

const SHEET := preload("res://sprites/hud/Ícones Pixelados de Teclas A e D.png")
const ICON_SIZE := Vector2(72, 72)
var fight: Node2D
var player: CharacterBody2D
var keys: Array[TextureRect] = []
var normal_textures: Array[AtlasTexture] = []
var pressed_textures: Array[AtlasTexture] = []
var clock := 0.0
var flash_direction := 0
var flash_time := 0.0

func _ready() -> void:
    name = "TranceKeyPrompt"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    size = Vector2(160, 76)
    normal_textures = [_texture(Rect2i(0, 0, 600, 380)), _texture(Rect2i(0, 380, 600, 344))]
    pressed_textures = [_texture(Rect2i(800, 0, 650, 380)), _texture(Rect2i(800, 380, 650, 344))]
    for index in range(2):
        var icon := TextureRect.new()
        icon.size = ICON_SIZE
        icon.pivot_offset = ICON_SIZE * 0.5
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
        icon.texture = normal_textures[index]
        add_child(icon)
        keys.append(icon)
    hide()

func _texture(cell: Rect2i) -> AtlasTexture:
    var texture := AtlasTexture.new()
    texture.atlas = SHEET
    var used := SHEET.get_image().get_region(cell).get_used_rect()
    texture.region = Rect2(Rect2i(cell.position + used.position, used.size))
    texture.filter_clip = true
    return texture

func flash_press(direction: int) -> void:
    flash_direction = direction
    flash_time = 0.12

func _process(delta: float) -> void:
    visible = fight.state == fight.State.SEDUCING and player.hp > 0 and not fight.finished
    if not visible:
        return
    clock += delta
    flash_time = maxf(0.0, flash_time - delta)
    var head := Vector2(player.combat_bounds.get_center().x, player.combat_bounds.position.y - player.jump_height)
    var head_on_screen: Vector2 = player.get_global_transform_with_canvas() * head
    var viewport_size := get_viewport_rect().size
    position = Vector2(clampf(head_on_screen.x - size.x * 0.5, 16, viewport_size.x - size.x - 16), clampf(head_on_screen.y - size.y - 16, 142, viewport_size.y - size.y - 16))
    var next_direction := -1 if fight.last_resistance_direction >= 0 else 1
    for index in range(2):
        var direction := -1 if index == 0 else 1
        var down := Input.is_key_pressed(KEY_A if index == 0 else KEY_D) or Input.is_action_pressed("ui_left" if index == 0 else "ui_right")
        down = down or (flash_time > 0.0 and flash_direction == direction)
        keys[index].texture = pressed_textures[index] if down else normal_textures[index]
        var expected := direction == next_direction
        keys[index].position = Vector2(index * 88, 0) + (Vector2(sin(clock * 55.0) * 3.0, cos(clock * 39.0) * 1.4) if expected and not down else Vector2.ZERO)
        keys[index].rotation = sin(clock * 43.0) * 0.035 if expected and not down else 0.0
        keys[index].modulate = Color.WHITE if expected or down else Color(0.55, 0.65, 0.61, 0.75)
