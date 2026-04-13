extends Node

signal state_changed(new_state: State)
signal floor_changed(new_floor: int)
signal run_started(start_floor: int)
signal run_ended

const MAX_FLOOR: int = 80
const VICTORY_SCENE_PATH := "res://scenes/ui/victory_screen.tscn"

enum State {
    BOOT,
    PLAYING,
    PAUSED,
    GAME_OVER,
}

var state: State = State.BOOT
var current_floor: int = 0
var selected_class_id: StringName = &"warrior"

var global_gold: int = 0
var account_upgrades: Dictionary = {
    "hp_bonus": 0,
    "atk_bonus": 0,
    "def_bonus": 0
}
const SAVE_PATH := "user://savegame.json"

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    load_data()

func start_run(start_floor: int = 1) -> void:
    current_floor = start_floor
    state = State.PLAYING
    get_tree().paused = false
    floor_changed.emit(current_floor)
    state_changed.emit(state)
    run_started.emit(current_floor)

func go_to_next_floor() -> void:
    if current_floor >= MAX_FLOOR:
        _show_victory_screen()
        return

    current_floor += 1
    floor_changed.emit(current_floor)

func end_run() -> void:
    state = State.GAME_OVER
    get_tree().paused = false
    save_data()
    state_changed.emit(state)
    run_ended.emit()

func toggle_pause() -> void:
    if state == State.GAME_OVER:
        return

    if state == State.PAUSED:
        state = State.PLAYING
        get_tree().paused = false
    else:
        state = State.PAUSED
        get_tree().paused = true

    state_changed.emit(state)

func set_selected_class(class_id: StringName) -> void:
    if class_id.is_empty():
        return
    selected_class_id = class_id

func _show_victory_screen() -> void:
    end_run()

    var scene_manager: Node = get_node_or_null("/root/SceneManager")
    if scene_manager != null and scene_manager.has_method("change_scene"):
        scene_manager.call("change_scene", VICTORY_SCENE_PATH)
        return

    get_tree().change_scene_to_file(VICTORY_SCENE_PATH)

func add_gold(amount: int) -> void:
    if amount > 0:
        global_gold += amount
        save_data()

func save_data() -> void:
    var data: Dictionary = {
        "gold": global_gold,
        "upgrades": account_upgrades
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(data))

func load_data() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
        if file != null:
            var parsed = JSON.parse_string(file.get_as_text())
            if typeof(parsed) == TYPE_DICTIONARY:
                global_gold = int(parsed.get("gold", 0))
                var loaded_upgrades = parsed.get("upgrades", {})
                if typeof(loaded_upgrades) == TYPE_DICTIONARY:
                    for key in account_upgrades.keys():
                        if loaded_upgrades.has(key):
                            account_upgrades[key] = int(loaded_upgrades[key])
