extends Node

signal state_changed(new_state: State)
signal floor_changed(new_floor: int)
signal run_started(start_floor: int)
signal run_ended

enum State {
    BOOT,
    PLAYING,
    PAUSED,
    GAME_OVER,
}

var state: State = State.BOOT
var current_floor: int = 0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func start_run(start_floor: int = 1) -> void:
    current_floor = start_floor
    state = State.PLAYING
    get_tree().paused = false
    floor_changed.emit(current_floor)
    state_changed.emit(state)
    run_started.emit(current_floor)

func go_to_next_floor() -> void:
    current_floor += 1
    floor_changed.emit(current_floor)

func end_run() -> void:
    state = State.GAME_OVER
    get_tree().paused = false
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

