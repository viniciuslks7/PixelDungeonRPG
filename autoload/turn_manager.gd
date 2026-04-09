extends Node

signal player_turn_started(turn_number: int)
signal player_turn_ended(turn_number: int)
signal turn_resolution_started(turn_number: int)
signal turn_resolution_finished(turn_number: int, consumed_turn: bool)
signal phase_changed(previous_phase: int, new_phase: int)

enum Phase {
    IDLE,
    PLAYER_INPUT,
    RESOLVING,
    ENEMY_TURN,
}

var phase: int = Phase.IDLE
var turn_number: int = 0

func start_run() -> void:
    turn_number = 1
    _set_phase(Phase.PLAYER_INPUT)
    player_turn_started.emit(turn_number)

func begin_resolution() -> bool:
    if phase != Phase.PLAYER_INPUT:
        return false

    _set_phase(Phase.RESOLVING)
    turn_resolution_started.emit(turn_number)
    return true

func resolve_player_action(consumed_turn: bool) -> void:
    if phase != Phase.RESOLVING:
        return

    turn_resolution_finished.emit(turn_number, consumed_turn)

    if consumed_turn:
        player_turn_ended.emit(turn_number)
        turn_number += 1

    _set_phase(Phase.PLAYER_INPUT)
    player_turn_started.emit(turn_number)

func _set_phase(new_phase: int) -> void:
    if phase == new_phase:
        return

    var previous_phase := phase
    phase = new_phase
    phase_changed.emit(previous_phase, new_phase)
    EventBus.turn_phase_changed.emit(previous_phase, new_phase, turn_number)
