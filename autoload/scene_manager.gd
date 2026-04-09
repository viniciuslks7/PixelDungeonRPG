extends Node

signal scene_changed(scene_path: String)

var current_scene_path: String = ""

func change_scene(scene_path: String) -> void:
    current_scene_path = scene_path
    get_tree().change_scene_to_file(scene_path)
    scene_changed.emit(scene_path)

func reload_current_scene() -> void:
    if current_scene_path.is_empty():
        current_scene_path = get_tree().current_scene.scene_file_path

    if current_scene_path.is_empty():
        push_warning("No current scene path available to reload.")
        return

    change_scene(current_scene_path)

