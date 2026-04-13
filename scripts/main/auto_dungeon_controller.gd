class_name AutoDungeonController
extends RefCounted

var _enabled: bool = false
var _path: Array[Vector2i] = []
var _path_index: int = 0

func is_enabled() -> bool:
    return _enabled

func clear_state() -> void:
    _enabled = false
    _path.clear()
    _path_index = 0

func on_dungeon_requested(current_floor_data: Dictionary) -> bool:
    _build_path(current_floor_data)
    _enabled = not _path.is_empty()
    return _enabled

func refresh_path_from_floor_data(current_floor_data: Dictionary) -> void:
    _build_path(current_floor_data)

func run_auto_player_action(player: Node, enemies: Array[Node], combat_controller: CombatController, is_cell_blocked: Callable) -> bool:
    if not _enabled:
        return false
    if TurnManager.phase != TurnManager.Phase.PLAYER_INPUT:
        return false
    if not is_instance_valid(player) or not player.is_alive():
        return false
    if not TurnManager.begin_resolution():
        return false

    var adjacent_target: Node = combat_controller.get_adjacent_attack_target(player, enemies)
    if adjacent_target != null:
        if player.try_use_active_skill_slot(0, adjacent_target):
            return false
        if player.try_attack(adjacent_target):
            return false
        TurnManager.resolve_player_action(false)
        return false

    var direction: Vector2i = _get_next_direction(player.get_grid_position())
    if direction == Vector2i.ZERO:
        _enabled = false
        TurnManager.resolve_player_action(false)
        return false

    var moved: bool = player.try_move_direction(direction, is_cell_blocked)
    if not moved:
        TurnManager.resolve_player_action(false)
    return moved

func _build_path(current_floor_data: Dictionary) -> void:
    _path.clear()
    _path_index = 0
    var raw_path: Array = current_floor_data.get("path", [])
    for cell in raw_path:
        if cell is Vector2i:
            _path.append(cell)

func _get_next_direction(player_cell: Vector2i) -> Vector2i:
    while _path_index < _path.size() and _path[_path_index] == player_cell:
        _path_index += 1

    if _path_index >= _path.size():
        return Vector2i.ZERO

    var next_cell: Vector2i = _path[_path_index]
    var delta: Vector2i = next_cell - player_cell
    if delta == Vector2i.ZERO:
        return Vector2i.ZERO

    if absi(delta.x) >= absi(delta.y):
        return Vector2i(signi(delta.x), 0)
    return Vector2i(0, signi(delta.y))
