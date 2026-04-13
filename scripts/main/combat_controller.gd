class_name CombatController
extends RefCounted

var _adjacent_cells: Array[Vector2i] = []

func configure(adjacent_cells: Array[Vector2i]) -> void:
    _adjacent_cells = adjacent_cells.duplicate()

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
