class_name Main
extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const TEST_ROOM_SCENE := preload("res://scenes/world/test_room.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")

const ADJACENT_CELLS: Array[Vector2i] = [
    Vector2i.RIGHT,
    Vector2i.DOWN,
    Vector2i.LEFT,
    Vector2i.UP,
]

var _current_room: Node
var _player: Node
var _enemy: Node

func _ready() -> void:
    TurnManager.player_turn_started.connect(_on_player_turn_started)
    TurnManager.enemy_turn_started.connect(_on_enemy_turn_started)
    EventBus.actor_moved.connect(_on_actor_moved)
    EventBus.actor_attacked.connect(_on_actor_attacked)
    EventBus.actor_damaged.connect(_on_actor_damaged)
    EventBus.actor_died.connect(_on_actor_died)
    EventBus.action_resolved.connect(_on_action_resolved)

    _spawn_room()
    _spawn_player()
    _spawn_enemy()

    GameManager.start_run()
    TurnManager.start_run()
    EventBus.bootstrap_completed.emit()

func _unhandled_input(event: InputEvent) -> void:
    if TurnManager.phase != TurnManager.Phase.PLAYER_INPUT:
        return

    if _is_attack_event(event):
        if not TurnManager.begin_resolution():
            return

        if not _try_player_melee_attack():
            EventBus.action_resolved.emit(_player.name, &"attack_miss")
            TurnManager.resolve_player_action(false)
        return

    var direction := _direction_from_event(event)
    if direction == Vector2i.ZERO:
        return

    if not TurnManager.begin_resolution():
        return

    var consumed_turn: bool = _player.try_move_direction(
        direction,
        Callable(self, "_is_cell_blocked")
    )

    if not consumed_turn:
        TurnManager.resolve_player_action(false)

func _spawn_room() -> void:
    _current_room = TEST_ROOM_SCENE.instantiate()
    add_child(_current_room)

func _spawn_player() -> void:
    _player = PLAYER_SCENE.instantiate()
    add_child(_player)
    _player.set_grid_position(_current_room.player_spawn_cell)
    _player.action_animation_finished.connect(_on_player_action_animation_finished)
    EventBus.player_spawned.emit(_player)

func _spawn_enemy() -> void:
    _enemy = ENEMY_SCENE.instantiate()
    add_child(_enemy)
    _enemy.set_grid_position(_current_room.enemy_spawn_cell)

func _is_cell_blocked(cell: Vector2i) -> bool:
    if _current_room.is_cell_blocked(cell):
        return true

    var enemy_at_cell: Node = _get_enemy_at_cell(cell)
    return enemy_at_cell != null

func _try_player_melee_attack() -> bool:
    var target: Node = _get_adjacent_attack_target()
    if target == null:
        return false

    return _player.try_attack(target)

func _get_adjacent_attack_target() -> Node:
    var player_cell: Vector2i = _player.get_grid_position()

    for offset in ADJACENT_CELLS:
        var target: Node = _get_enemy_at_cell(player_cell + offset)
        if target != null:
            return target

    return null

func _get_enemy_at_cell(cell: Vector2i) -> Node:
    if not is_instance_valid(_enemy) or not _enemy.is_alive():
        return null

    if _enemy.get_grid_position() != cell:
        return null

    return _enemy

func _is_adjacent(first_cell: Vector2i, second_cell: Vector2i) -> bool:
    var delta := first_cell - second_cell
    return absi(delta.x) + absi(delta.y) == 1

func _on_player_turn_started(_turn_number: int) -> void:
    EventBus.player_turn_ready.emit()

func _on_enemy_turn_started(_turn_number: int) -> void:
    _resolve_enemy_turn.call_deferred()

func _resolve_enemy_turn() -> void:
    if TurnManager.phase != TurnManager.Phase.ENEMY_TURN:
        return

    if not is_instance_valid(_enemy) or not _enemy.is_alive():
        TurnManager.finish_enemy_turn()
        return

    if not is_instance_valid(_player) or not _player.is_alive():
        TurnManager.finish_enemy_turn()
        return

    var enemy_cell: Vector2i = _enemy.get_grid_position()
    var player_cell: Vector2i = _player.get_grid_position()

    if _is_adjacent(enemy_cell, player_cell):
        _enemy.try_attack(_player)
    else:
        EventBus.action_resolved.emit(_enemy.name, &"wait")

    TurnManager.finish_enemy_turn()

func _on_player_action_animation_finished() -> void:
    TurnManager.resolve_player_action(true)

func _on_actor_moved(actor_name: String, from_cell: Vector2i, to_cell: Vector2i) -> void:
    print("%s moveu de %s para %s" % [actor_name, from_cell, to_cell])

func _on_actor_attacked(attacker_name: String, target_name: String, damage: int) -> void:
    print("%s atacou %s causando %d de dano" % [attacker_name, target_name, damage])

func _on_actor_damaged(actor_name: String, amount: int, current_health: int, max_health: int) -> void:
    print("%s recebeu %d de dano (%d/%d)" % [actor_name, amount, current_health, max_health])

func _on_actor_died(actor_name: String) -> void:
    print("%s morreu" % actor_name)

func _on_action_resolved(actor_name: String, action_name: StringName) -> void:
    print("%s executou a acao %s" % [actor_name, action_name])

func _direction_from_event(event: InputEvent) -> Vector2i:
    if event is not InputEventKey:
        return Vector2i.ZERO

    var key_event := event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return Vector2i.ZERO

    match key_event.physical_keycode:
        KEY_W, KEY_UP:
            return Vector2i.UP
        KEY_S, KEY_DOWN:
            return Vector2i.DOWN
        KEY_A, KEY_LEFT:
            return Vector2i.LEFT
        KEY_D, KEY_RIGHT:
            return Vector2i.RIGHT
        _:
            return Vector2i.ZERO

func _is_attack_event(event: InputEvent) -> bool:
    if event is not InputEventKey:
        return false

    var key_event := event as InputEventKey
    return key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_SPACE
