extends Node

const SAVE_PATH := "user://campaign_progress.cfg"
const STAGE_PATHS: Array[String] = [
    "res://main.tscn", "res://ratanaba2.tscn",
    "res://rio_negro3.tscn", "res://rio_negro4.tscn",
    "res://floresta5.tscn"
]
const IMPLEMENTED_STAGES := 5

static func stage_path(index: int) -> String:
    return STAGE_PATHS[index] if index >= 0 and index < IMPLEMENTED_STAGES else ""

static func completed_stages() -> int:
    var save := ConfigFile.new()
    if save.load(SAVE_PATH) != OK:
        return 0
    return clampi(int(save.get_value("campaign", "completed", 0)), 0, IMPLEMENTED_STAGES)

static func is_available(index: int) -> bool:
    return index >= 0 and index < IMPLEMENTED_STAGES and index <= completed_stages()

static func complete_stage(index: int) -> void:
    if stage_path(index).is_empty():
        return
    var completed := completed_stages()
    var save := ConfigFile.new()
    save.load(SAVE_PATH)
    var changed := false
    if index == completed and index < IMPLEMENTED_STAGES:
        save.set_value("campaign", "completed", completed + 1)
        changed = true
    if int(save.get_value("checkpoint", "stage", -1)) == index:
        save.erase_section("checkpoint")
        changed = true
    if not changed:
        return
    var error := save.save(SAVE_PATH)
    if error != OK:
        push_error("Could not save campaign progress: %s" % error)

static func save_checkpoint(index: int, checkpoint_id: String, position: Vector2) -> void:
    if stage_path(index).is_empty():
        return
    var save := ConfigFile.new()
    save.load(SAVE_PATH)
    save.set_value("checkpoint", "stage", index)
    save.set_value("checkpoint", "id", checkpoint_id)
    save.set_value("checkpoint", "position", position)
    var error := save.save(SAVE_PATH)
    if error != OK:
        push_error("Could not save checkpoint: %s" % error)

static func checkpoint() -> Dictionary:
    var save := ConfigFile.new()
    if save.load(SAVE_PATH) != OK or not save.has_section_key("checkpoint", "position"):
        return {}
    var index := int(save.get_value("checkpoint", "stage", -1))
    var checkpoint_id := str(save.get_value("checkpoint", "id", ""))
    var position = save.get_value("checkpoint", "position", null)
    if stage_path(index).is_empty() or not position is Vector2 or not position.is_finite():
        return {}
    var allowed_ids := ["start"]
    if index == 0:
        allowed_ids.append("tutorial_combat")
    elif index in [1, 3]:
        allowed_ids.append_array(["wave_2", "boss"])
    elif index == 4:
        allowed_ids.append_array(["trecho_2", "trecho_3", "caverna"])
    if not checkpoint_id in allowed_ids:
        return {}
    return {"stage": index, "id": checkpoint_id, "position": position}
