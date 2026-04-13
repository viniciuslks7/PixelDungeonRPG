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
        if player.has_method("try_pet_attack"):
            player.try_pet_attack(adjacent_target)
            
        var skill_slot: int = _find_first_available_skill_slot(player)
        if skill_slot >= 0 and player.try_use_active_skill_slot(skill_slot, adjacent_target):
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

func _find_first_available_skill_slot(player: Node) -> int:
    if not ("active_skills" in player):
        return -1

    var available_mana: int = _get_player_available_mana(player)
    var skills_variant: Variant = player.active_skills
    if typeof(skills_variant) != TYPE_ARRAY:
        return -1

    var equipped_skills: Array = skills_variant as Array
    for slot_index in range(equipped_skills.size()):
        var skill_data: SkillData = equipped_skills[slot_index] as SkillData
        if skill_data == null or not skill_data.is_active():
            continue
        if _get_player_skill_cooldown(player, skill_data.id) > 0:
            continue
        if available_mana < skill_data.mana_cost:
            continue
        return slot_index
    return -1

func _get_player_skill_cooldown(player: Node, skill_id: StringName) -> int:
    if player.has_method("_get_skill_cooldown"):
        return int(player.call("_get_skill_cooldown", skill_id))

    if "_skill_cooldowns" in player:
        var cooldowns: Dictionary = player._skill_cooldowns
        return int(cooldowns.get(skill_id, 0))

    return 0

func _get_player_available_mana(player: Node) -> int:
    if "current_mana" in player:
        return maxi(int(player.current_mana), 0)

    if player.has_method("get_current_mana"):
        return maxi(int(player.call("get_current_mana")), 0)

    if "mana" in player:
        return maxi(int(player.mana), 0)

    if "core_attributes" in player:
        var attributes: Dictionary = player.core_attributes
        return maxi(int(attributes.get(&"mana_max", attributes.get("mana_max", 0))), 0)

    return 0

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
