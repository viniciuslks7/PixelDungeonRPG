class_name CombatController
extends RefCounted

var _adjacent_cells: Array[Vector2i] = []

func configure(adjacent_cells: Array[Vector2i]) -> void:
    _adjacent_cells = adjacent_cells.duplicate()

func handle_attack_or_skill_input(
    event: InputEvent,
    player: Node,
    enemies: Array[Node],
    is_attack_event: Callable,
    skill_slot_from_event: Callable
) -> bool:
    if not is_instance_valid(player):
        return false

    if is_attack_event.call(event):
        if not TurnManager.begin_resolution():
            return true

        if not try_player_melee_attack(player, enemies):
            EventBus.action_resolved.emit(player.name, &"attack_miss")
            TurnManager.resolve_player_action(false)
        return true

    var skill_slot: int = int(skill_slot_from_event.call(event))
    if skill_slot < 0:
        return false

    if not TurnManager.begin_resolution():
        return true

    var skill_target: Node = get_adjacent_attack_target(player, enemies)
    if not player.try_use_active_skill_slot(skill_slot, skill_target):
        TurnManager.resolve_player_action(false)
    return true

func try_player_melee_attack(player: Node, enemies: Array[Node]) -> bool:
    var target: Node = get_adjacent_attack_target(player, enemies)
    if target == null:
        return false
    return player.try_attack(target)

func get_adjacent_attack_target(player: Node, enemies: Array[Node]) -> Node:
    if not is_instance_valid(player):
        return null

    var player_cell: Vector2i = player.get_grid_position()
    for offset in _adjacent_cells:
        var candidate_cell: Vector2i = player_cell + offset
        var enemy_at_cell: Node = _get_enemy_at_cell(candidate_cell, enemies)
        if enemy_at_cell != null:
            return enemy_at_cell
    return null

func _get_enemy_at_cell(cell: Vector2i, enemies: Array[Node]) -> Node:
    for enemy in enemies:
        if not is_instance_valid(enemy) or not enemy.is_alive():
            continue
        if enemy.get_grid_position() == cell:
            return enemy
    return null
