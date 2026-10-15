extends SceneTree

# Run after changing the source sheet:
# Godot --headless --path teste --script scripts/ExportDialoguePortraits.gd
const SOURCE_PATH := "res://sprites/dialogo/sprie sheet cabeças personagens.png"
const REGIONS := preload("res://scripts/DialoguePortraits.gd").SPEAKER_REGIONS

# Each (row, left, right) describes only the contaminated top edge of a head.
# Some red fragments touch the artwork, so a connected-component crop alone
# removes neither those fragments nor the horizontal smears above the hats.
# Bounds follow the original dark outline and leave the rest of the art intact.
const TOP_EDGES := {
    "player": [
        [Vector3i(4, 163, 198), Vector3i(6, 158, 203), Vector3i(8, 151, 226), Vector3i(10, 145, 231), Vector3i(16, 127, 235), Vector3i(25, 109, 244), Vector3i(36, 86, 252)],
        [Vector3i(4, 159, 197), Vector3i(6, 151, 202), Vector3i(8, 146, 225), Vector3i(10, 139, 231), Vector3i(16, 125, 235), Vector3i(25, 104, 246), Vector3i(36, 82, 257)],
        [Vector3i(4, 153, 189), Vector3i(6, 148, 193), Vector3i(8, 143, 215), Vector3i(10, 138, 218), Vector3i(16, 117, 223), Vector3i(25, 97, 235), Vector3i(36, 75, 248)],
    ],
    "cuca": [
        [Vector3i(2, 122, 219), Vector3i(4, 108, 225), Vector3i(6, 96, 231), Vector3i(10, 88, 236), Vector3i(16, 80, 242)],
        [Vector3i(2, 131, 206), Vector3i(4, 124, 211), Vector3i(6, 118, 215), Vector3i(10, 111, 237), Vector3i(16, 103, 245)],
        [Vector3i(2, 134, 201), Vector3i(4, 129, 207), Vector3i(6, 125, 212), Vector3i(8, 89, 215), Vector3i(10, 83, 217), Vector3i(16, 72, 222)],
    ],
    "vitoria": [
        [Vector3i(2, 144, 175), Vector3i(4, 137, 185), Vector3i(6, 133, 194), Vector3i(10, 123, 207), Vector3i(16, 113, 220)],
        [Vector3i(2, 156, 194), Vector3i(4, 146, 198), Vector3i(6, 144, 207), Vector3i(10, 135, 220), Vector3i(16, 124, 232)],
        [Vector3i(2, 144, 171), Vector3i(4, 130, 183), Vector3i(6, 131, 197), Vector3i(10, 121, 204), Vector3i(16, 112, 219)],
    ],
}

func _initialize() -> void:
    if "--measure-load" in OS.get_cmdline_user_args():
        var load_start := Time.get_ticks_usec()
        preload("res://scripts/DialoguePortraits.gd").build()
        print("Runtime portrait setup: ", Time.get_ticks_usec() - load_start, "µs")
        quit()
        return
    var start := Time.get_ticks_msec()
    var portraits := _extract()
    print("Portrait source: ", _load_image(SOURCE_PATH).get_size())
    print("Extraction time: ", Time.get_ticks_msec() - start, "ms")
    DirAccess.make_dir_recursive_absolute("res://sprites/dialogo/portraits")
    for character: String in portraits:
        for expression: int in range(3):
            var image: Image = portraits[character][expression]
            var path := "res://sprites/dialogo/portraits/%s_%d.png" % [character, expression]
            if "--check" in OS.get_cmdline_user_args():
                var exported := _load_image(path)
                if exported == null or exported.get_size() != image.get_size() or exported.get_data() != image.get_data():
                    push_error("Portrait is missing or differs from the current sheet: " + path)
                    quit(1)
                    return
            elif image.save_png(path) != OK:
                push_error("Could not export portrait: " + path)
                quit(1)
                return
        print(character, ": ", portraits[character][0].get_size(), " (shared by all 3 expressions)")
    if "--check" in OS.get_cmdline_user_args():
        print("PASS: all 12 portraits match the source sheet and their shared canvases")
    quit()

func _extract() -> Dictionary:
    # Read the PNG directly so a sheet edit is exported even before reimporting.
    var source := _load_image(SOURCE_PATH)
    source.convert(Image.FORMAT_RGBA8)
    var result: Dictionary = {}
    for character: String in REGIONS:
        var images: Array[Image] = []
        var common_rect := Rect2i()
        for expression: int in range(REGIONS[character].size()):
            var image := source.get_region(REGIONS[character][expression])
            _trim_top_edge(image, character, expression)
            image = _clean_portrait(image)
            images.append(image)
            common_rect = image.get_used_rect() if common_rect.size == Vector2i.ZERO else common_rect.merge(image.get_used_rect())
        var expressions: Array[Image] = []
        for image: Image in images:
            expressions.append(image.get_region(common_rect))
        result[character] = expressions
    return result

func _load_image(path: String) -> Image:
    var image := Image.new()
    if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK:
        return null
    image.convert(Image.FORMAT_RGBA8)
    return image

func _trim_top_edge(image: Image, character: String, expression: int) -> void:
    if not TOP_EDGES.has(character):
        return
    var edge: Array = TOP_EDGES[character][expression]
    var pixels := image.get_data()
    var width := image.get_width()
    var segment := 0
    for y: int in range(edge[-1].x + 1):
        var left := width
        var right := 0
        if y >= edge[0].x:
            while segment < edge.size() - 2 and y > edge[segment + 1].x:
                segment += 1
            var first: Vector3i = edge[segment]
            var last: Vector3i = edge[segment + 1]
            var progress := float(y - first.x) / float(last.x - first.x)
            left = floori(lerpf(first.y, last.y, progress))
            right = ceili(lerpf(first.z, last.z, progress))
        for x: int in range(width):
            var pixel := (y * width + x) * 4
            var foreign_red := character != "player" and pixels[pixel] >= 100 and pixels[pixel + 1] < pixels[pixel] * 0.55
            if x < left or x > right or foreign_red:
                pixels[pixel + 3] = 0
    image.set_data(width, image.get_height(), false, Image.FORMAT_RGBA8, pixels)

func _clean_portrait(image: Image) -> Image:
    # Loose pixels from neighboring portraits must not enter the dialogue panel.
    # Preserve the original antialiasing around the main head as well.
    var width := image.get_width()
    var height := image.get_height()
    var pixels := image.get_data()
    var visited := PackedByteArray()
    visited.resize(width * height)
    var largest := PackedInt32Array()
    for start: int in range(width * height):
        if visited[start] != 0 or pixels[start * 4 + 3] < 16:
            continue
        var component := PackedInt32Array([start])
        visited[start] = 1
        var cursor := 0
        while cursor < component.size():
            var current := component[cursor]
            cursor += 1
            var x := current % width
            var y: int = current / width
            for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
                var next_x := x + direction.x
                var next_y := y + direction.y
                if next_x < 0 or next_x >= width or next_y < 0 or next_y >= height:
                    continue
                var next := next_y * width + next_x
                if visited[next] == 0 and pixels[next * 4 + 3] >= 16:
                    visited[next] = 1
                    component.append(next)
        if component.size() > largest.size():
            largest = component
    var keep := PackedByteArray()
    keep.resize(width * height)
    for pixel: int in largest:
        keep[pixel] = 1
    var outline := keep.duplicate()
    for pixel: int in largest:
        var x := pixel % width
        var y: int = pixel / width
        for offset_y: int in range(-2, 3):
            for offset_x: int in range(-2, 3):
                var next_x := x + offset_x
                var next_y := y + offset_y
                if next_x >= 0 and next_x < width and next_y >= 0 and next_y < height:
                    outline[next_y * width + next_x] = 1
    for pixel: int in range(width * height):
        if outline[pixel] == 0:
            pixels[pixel * 4 + 3] = 0
        if pixels[pixel * 4 + 3] == 0:
            # Empty pixels must not carry the old strip's RGB into filtering.
            pixels[pixel * 4] = 0
            pixels[pixel * 4 + 1] = 0
            pixels[pixel * 4 + 2] = 0
    return Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, pixels)
