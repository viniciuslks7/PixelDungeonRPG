class_name EnemyAIController
extends RefCounted

var _enemy_turn_queue: Array[Node] = []
var _active_enemy: Node
var _active_enemy_actions_remaining: int = 0

func clear_state() -> void:
    _enemy_turn_queue.clear()
    _active_enemy = null
    _active_enemy_actions_remaining = 0

func begin_enemy_turn(living_enemies: Array[Node], schedule_next: Callable) -> void:
    _enemy_turn_queue = living_enemies.duplicate()
    _active_enemy = null
    _active_enemy_actions_remaining = 0
    schedule_next.call_deferred()

func process_next_enemy_turn(player: Node, is_cell_blocked_for_enemy: Callable, schedule_next: Callable) -> void:
    if TurnManager.phase != TurnManager.Phase.ENEMY_TURN:
        return

    if not is_instance_valid(player) or not player.is_alive():
        clear_state()
        TurnManager.finish_enemy_turn()
        return

    while not _enemy_turn_queue.is_empty():
        var next_enemy: Node = _enemy_turn_queue.pop_front()
        if not is_instance_valid(next_enemy) or not next_enemy.is_alive():
            continue

        _active_enemy = next_enemy
        _active_enemy_actions_remaining = _get_enemy_actions_per_turn(next_enemy)
        _resolve_single_enemy_turn(next_enemy, player, is_cell_blocked_for_enemy, schedule_next)
        return

    clear_state()
    TurnManager.finish_enemy_turn()

func on_enemy_action_animation_finished(player: Node, is_cell_blocked_for_enemy: Callable, schedule_next: Callable) -> void:
    if is_instance_valid(_active_enemy) and _active_enemy.is_alive() and _active_enemy_actions_remaining > 0:
        _resolve_single_enemy_turn(_active_enemy, player, is_cell_blocked_for_enemy, schedule_next)
        return

    _advance_enemy_turn_queue(schedule_next)

func _resolve_single_enemy_turn(enemy: Node, player: Node, is_cell_blocked_for_enemy: Callable, schedule_next: Callable) -> void:
    if not is_instance_valid(enemy) or not enemy.is_alive():
        schedule_next.call_deferred()
        return

    if not is_instance_valid(player) or not player.is_alive():
        clear_state()
        TurnManager.finish_enemy_turn()
        return

    var enemy_cell: Vector2i = enemy.get_grid_position()
    var player_cell: Vector2i = player.get_grid_position()

    if _is_adjacent(enemy_cell, player_cell):
        _active_enemy_actions_remaining = 0
        enemy.try_attack(player)
        return

    var moved: bool = false
    if _active_enemy_actions_remaining > 0:
        var step: Vector2i = _get_enemy_step_for_behavior(enemy, enemy_cell, player_cell, is_cell_blocked_for_enemy)
        if step != Vector2i.ZERO and enemy.try_move_direction(step, is_cell_blocked_for_enemy):
            _active_enemy_actions_remaining -= 1
            moved = true

    if moved:
        return

    EventBus.action_resolved.emit(enemy.display_name, &"wait")
    _advance_enemy_turn_queue(schedule_next)

func _advance_enemy_turn_queue(schedule_next: Callable) -> void:
    _active_enemy = null
    _active_enemy_actions_remaining = 0
    schedule_next.call_deferred()

func _get_enemy_step_for_behavior(enemy: Node, enemy_cell: Vector2i, player_cell: Vector2i, is_cell_blocked_for_enemy: Callable) -> Vector2i:
    if enemy == null or enemy.monster_data == null:
        return _get_enemy_step_towards_player(enemy_cell, player_cell, is_cell_blocked_for_enemy)

    var distance_to_player: int = _get_manhattan_distance(enemy_cell, player_cell)
    match enemy.monster_data.behavior:
        MonsterData.BehaviorType.PASSIVE:
            return Vector2i.ZERO
        MonsterData.BehaviorType.SKIRMISHER:
            if distance_to_player > 2:
                return _get_enemy_step_towards_player(enemy_cell, player_cell, is_cell_blocked_for_enemy)
            return Vector2i.ZERO
        _:
            return _get_enemy_step_towards_player(enemy_cell, player_cell, is_cell_blocked_for_enemy)

func _get_enemy_step_towards_player(enemy_cell: Vector2i, player_cell: Vector2i, is_cell_blocked_for_enemy: Callable) -> Vector2i:
    var candidates: Array[Vector2i] = []
    var delta: Vector2i = player_cell - enemy_cell

    if absi(delta.x) >= absi(delta.y):
        candidates.append(Vector2i(signi(delta.x), 0))
        candidates.append(Vector2i(0, signi(delta.y)))
    else:
        candidates.append(Vector2i(0, signi(delta.y)))
        candidates.append(Vector2i(signi(delta.x), 0))

    for candidate in candidates:
        if candidate == Vector2i.ZERO:
            continue
        if not is_cell_blocked_for_enemy.call(enemy_cell + candidate):
            return candidate

    return Vector2i.ZERO

func _is_adjacent(first_cell: Vector2i, second_cell: Vector2i) -> bool:
    var delta: Vector2i = first_cell - second_cell
    return absi(delta.x) + absi(delta.y) == 1

func _get_enemy_actions_per_turn(enemy: Node) -> int:
    if enemy == null or enemy.monster_data == null:
        return 1
    return 2 if enemy.monster_data.speed >= 4 else 1

func _get_manhattan_distance(from_cell: Vector2i, to_cell: Vector2i) -> int:
    var delta: Vector2i = to_cell - from_cell
    return absi(delta.x) + absi(delta.y)
