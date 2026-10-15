extends RefCounted

# The updated 1331-by-1181 sheet has three expressions in each of four rows.
# Keep the full head here; the exporter masks the stray paint along row edges.
# All three expressions use one common canvas so speaking never resizes them.
const SPEAKER_REGIONS := {
    "boitata": [Rect2i(0, 0, 380, 278), Rect2i(400, 0, 380, 278), Rect2i(800, 0, 380, 278)],
    "player": [Rect2i(0, 300, 380, 250), Rect2i(400, 300, 380, 250), Rect2i(800, 300, 380, 250)],
    "cuca": [Rect2i(0, 600, 380, 252), Rect2i(400, 600, 380, 252), Rect2i(800, 600, 380, 252)],
    # The horizontal magenta smear begins at y=1116 beneath the shoulders.
    "vitoria": [Rect2i(0, 900, 380, 216), Rect2i(400, 900, 380, 216), Rect2i(800, 900, 380, 216)],
}

const EXPRESSIONS := {
    "boitata": [preload("res://sprites/dialogo/portraits/boitata_0.png"), preload("res://sprites/dialogo/portraits/boitata_1.png"), preload("res://sprites/dialogo/portraits/boitata_2.png")],
    "player": [preload("res://sprites/dialogo/portraits/player_0.png"), preload("res://sprites/dialogo/portraits/player_1.png"), preload("res://sprites/dialogo/portraits/player_2.png")],
    "cuca": [preload("res://sprites/dialogo/portraits/cuca_0.png"), preload("res://sprites/dialogo/portraits/cuca_1.png"), preload("res://sprites/dialogo/portraits/cuca_2.png")],
    "vitoria": [preload("res://sprites/dialogo/portraits/vitoria_0.png"), preload("res://sprites/dialogo/portraits/vitoria_1.png"), preload("res://sprites/dialogo/portraits/vitoria_2.png")],
}

static var _cached: Dictionary = {}

static func build() -> Dictionary:
    if not _cached.is_empty():
        return _cached
    for character: String in EXPRESSIONS:
        var expressions: Array[AtlasTexture] = []
        for texture: Texture2D in EXPRESSIONS[character]:
            var atlas := AtlasTexture.new()
            atlas.atlas = texture
            atlas.region = Rect2(Vector2.ZERO, texture.get_size())
            atlas.filter_clip = true
            expressions.append(atlas)
        _cached[character] = expressions
    return _cached
