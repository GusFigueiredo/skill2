extends Node

const SAVE_PATH := "user://campaign_progress.cfg"
const STAGE_PATHS: Array[String] = [
    "res://main.tscn", "res://ratanaba2.tscn",
    "res://rio_negro3.tscn", "res://rio_negro4.tscn"
]
const IMPLEMENTED_STAGES := 4

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
    var completed := completed_stages()
    if index != completed or index >= IMPLEMENTED_STAGES:
        return
    var save := ConfigFile.new()
    save.set_value("campaign", "completed", completed + 1)
    var error := save.save(SAVE_PATH)
    if error != OK:
        push_error("Could not save campaign progress: %s" % error)
