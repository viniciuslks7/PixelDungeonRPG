class_name Main
extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const WARRIOR_DATA := preload("res://data/classes/warrior.tres")
const ARCHER_DATA := preload("res://data/classes/archer.tres")
const MAGE_DATA := preload("res://data/classes/mage.tres")
const TEST_ROOM_SCENE := preload("res://scenes/world/test_room.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const WORLD_ITEM_SCENE := preload("res://scenes/items/world_item.tscn")
const DUNGEON_CHEST_SCENE := preload("res://scenes/items/dungeon_chest.tscn")
const DUNGEON_PROP_SCENE := preload("res://scenes/world/dungeon_prop.tscn")
const SLIME_DATA := preload("res://data/monsters/slime.tres")
const SKELETON_DATA := preload("res://data/monsters/skeleton.tres")
const BAT_DATA := preload("res://data/monsters/bat.tres")
const SHORT_SWORD_DATA := preload("res://data/items/short_sword.tres")
const WOODEN_SHIELD_DATA := preload("res://data/items/wooden_shield.tres")
const LONG_BOW_DATA := preload("res://data/items/long_bow.tres")
const APPRENTICE_STAFF_DATA := preload("res://data/items/apprentice_staff.tres")
const HEALTH_POTION_DATA := preload("res://data/items/health_potion.tres")
const FLOOR_KEY_DATA := preload("res://data/items/floor_key.tres")
const LEATHER_HELMET_DATA := preload("res://data/items/leather_helmet.tres")
const LEATHER_ARMOR_DATA := preload("res://data/items/leather_armor.tres")
const LEATHER_GLOVES_DATA := preload("res://data/items/leather_gloves.tres")
const LEATHER_BOOTS_DATA := preload("res://data/items/leather_boots.tres")
const GUARDIAN_WHELP_PET_DATA := preload("res://data/pets/guardian_whelp.tres")
const RANGER_HAWK_PET_DATA := preload("res://data/pets/ranger_hawk.tres")
const ARCANE_FAIRY_PET_DATA := preload("res://data/pets/arcane_fairy.tres")
const IRON_WOLF_MOUNT_DATA := preload("res://data/mounts/iron_wolf.tres")
const ROYAL_STAG_MOUNT_DATA := preload("res://data/mounts/royal_stag.tres")
const TEST_ENEMY_DATA: Array[MonsterData] = [
    SLIME_DATA,
    SKELETON_DATA,
    BAT_DATA,
]
const CLASS_DATA_BY_ID: Dictionary = {
    &"warrior": WARRIOR_DATA,
    &"archer": ARCHER_DATA,
    &"mage": MAGE_DATA,
}
const AVAILABLE_PETS: Array[PetData] = [
    GUARDIAN_WHELP_PET_DATA,
    RANGER_HAWK_PET_DATA,
    ARCANE_FAIRY_PET_DATA,
]
const AVAILABLE_MOUNTS: Array[MountData] = [
    IRON_WOLF_MOUNT_DATA,
    ROYAL_STAG_MOUNT_DATA,
]

const ADJACENT_CELLS: Array[Vector2i] = [
    Vector2i.RIGHT,
    Vector2i.DOWN,
    Vector2i.LEFT,
    Vector2i.UP,
]
const DUNGEON_PROP_TYPE_TORCH: int = 0
const DUNGEON_PROP_TYPE_ALTAR: int = 1
const DUNGEON_PROP_TYPE_STAIRS: int = 2

var _current_room: Node
var _player: Node
var _enemy: Node
var _enemies: Array[Node] = []
var _ground_items: Array[Node] = []
var _enemy_turn_queue: Array[Node] = []
var _active_enemy: Node
var _active_enemy_actions_remaining: int = 0
var _current_floor_data: Dictionary = {}
var _auto_dungeon_enabled: bool = false
var _auto_path: Array[Vector2i] = []
var _auto_path_index: int = 0
var _dungeon_chest: DungeonChest
var _dungeon_props: Array[Node] = []
var _active_pet_index: int = 0
var _active_mount_index: int = 0

@onready var _world_root: Node2D = $WorldRoot
@onready var _game_hud: Node = $GameHUD

func _ready() -> void:
    TurnManager.player_turn_started.connect(_on_player_turn_started)
    TurnManager.enemy_turn_started.connect(_on_enemy_turn_started)
    get_viewport().size_changed.connect(_on_viewport_size_changed)
    if is_instance_valid(_game_hud):
        if _game_hud.has_signal("dungeon_requested"):
            _game_hud.dungeon_requested.connect(_on_dungeon_requested)
        if _game_hud.has_signal("inventory_item_requested"):
            _game_hud.inventory_item_requested.connect(_on_inventory_item_requested)
        if _game_hud.has_signal("inventory_unequip_requested"):
            _game_hud.inventory_unequip_requested.connect(_on_inventory_unequip_requested)
        if _game_hud.has_signal("pet_cycle_requested"):
            _game_hud.pet_cycle_requested.connect(_cycle_player_pet)
        if _game_hud.has_signal("mount_cycle_requested"):
            _game_hud.mount_cycle_requested.connect(_cycle_player_mount)
    EventBus.actor_moved.connect(_on_actor_moved)
    EventBus.actor_attacked.connect(_on_actor_attacked)
    EventBus.actor_damaged.connect(_on_actor_damaged)
    EventBus.actor_died.connect(_on_actor_died)
    EventBus.skill_used.connect(_on_skill_used)
    EventBus.item_picked_up.connect(_on_item_picked_up)
    EventBus.item_used.connect(_on_item_used)
    EventBus.inventory_changed.connect(_on_inventory_changed)
    EventBus.equipment_changed.connect(_on_equipment_changed)
    EventBus.pet_changed.connect(_on_pet_changed)
    EventBus.mount_changed.connect(_on_mount_changed)
    EventBus.chest_opened.connect(_on_chest_opened)
    EventBus.action_resolved.connect(_on_action_resolved)

    _spawn_room()
    _spawn_player()
    _spawn_items()
    _spawn_chest()
    _spawn_dungeon_props()
    _spawn_enemies()
    _position_world_in_map.call_deferred()

    GameManager.start_run()
    TurnManager.start_run()
    EventBus.bootstrap_completed.emit()

func _unhandled_input(event: InputEvent) -> void:
    if _auto_dungeon_enabled:
        return

    if _is_swap_pet_event(event):
        _cycle_player_pet()
        return

    if _is_swap_mount_event(event):
        _cycle_player_mount()
        return

    if TurnManager.phase != TurnManager.Phase.PLAYER_INPUT:
        return

    if _is_attack_event(event):
        if not TurnManager.begin_resolution():
            return

        if not _try_player_melee_attack():
            EventBus.action_resolved.emit(_player.name, &"attack_miss")
            TurnManager.resolve_player_action(false)
        return

    var skill_slot: int = _skill_slot_from_event(event)
    if skill_slot >= 0:
        if not TurnManager.begin_resolution():
            return

        var skill_target: Node = _get_adjacent_attack_target()
        if not _player.try_use_active_skill_slot(skill_slot, skill_target):
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
    _world_root.add_child(_current_room)
    _apply_floor_data_to_room()
    _current_room.queue_redraw()

func _spawn_player() -> void:
    _player = PLAYER_SCENE.instantiate()
    _player.class_data = _get_selected_class_data()
    _world_root.add_child(_player)
    _player.set_grid_position(_current_room.player_spawn_cell)
    var starter_pet: PetData = _get_starter_pet_for_selected_class()
    var starter_mount: MountData = _get_starter_mount_for_selected_class()
    _player.equip_pet(starter_pet)
    _player.equip_mount(starter_mount)
    if _player.health != null:
        _player.health.current_health = _player.health.max_health
        _player.health.health_changed.emit(_player.health.current_health, _player.health.max_health)
    _active_pet_index = maxi(AVAILABLE_PETS.find(starter_pet), 0)
    _active_mount_index = maxi(AVAILABLE_MOUNTS.find(starter_mount), 0)
    _player.action_animation_finished.connect(_on_player_action_animation_finished)
    EventBus.player_spawned.emit(_player)

func _get_selected_class_data() -> CharacterClassData:
    var class_id: StringName = GameManager.selected_class_id
    return CLASS_DATA_BY_ID.get(class_id, WARRIOR_DATA) as CharacterClassData

func _get_dungeon_service() -> Node:
    return get_node_or_null("/root/DungeonService")

func _apply_floor_data_to_room() -> void:
    var floor_level: int = maxi(GameManager.current_floor, 1)
    var dungeon_service: Node = _get_dungeon_service()
    if dungeon_service == null:
        push_error("DungeonService autoload nao encontrado.")
        _current_floor_data = {}
        return

    _current_floor_data = dungeon_service.call("get_floor_data", floor_level)
    if _current_floor_data.is_empty():
        return

    var floor_spawn_cell: Variant = _current_floor_data.get("player_spawn_cell", _current_room.player_spawn_cell)
    if floor_spawn_cell is Vector2i:
        _current_room.player_spawn_cell = floor_spawn_cell

    var enemy_cells_raw: Array = _current_floor_data.get("enemy_cells", [])
    var enemy_cells: Array[Vector2i] = []
    for cell in enemy_cells_raw:
        if cell is Vector2i:
            enemy_cells.append(cell)
    if not enemy_cells.is_empty():
        _current_room.enemy_spawn_cells = enemy_cells

    var path_cells_raw: Array = _current_floor_data.get("path", [])
    var path_cells: Array[Vector2i] = []
    for cell in path_cells_raw:
        if cell is Vector2i:
            path_cells.append(cell)
    if path_cells.size() >= 3:
        var item_spawn_cells: Array[Vector2i] = []
        item_spawn_cells.append(path_cells[1])
        item_spawn_cells.append(path_cells[2])
        _current_room.item_spawn_cells = item_spawn_cells

func _spawn_items() -> void:
    _ground_items.clear()
    var starter_loot: Array[ItemData] = _get_starter_loot_for_selected_class()

    for index in range(min(_current_room.item_spawn_cells.size(), starter_loot.size())):
        var world_item := WORLD_ITEM_SCENE.instantiate()
        world_item.item_data = starter_loot[index]
        world_item.name = "%s_%d" % [String(world_item.item_data.id), index + 1]
        _world_root.add_child(world_item)
        world_item.set_grid_position(_current_room.item_spawn_cells[index], _current_room.cell_size)
        _ground_items.append(world_item)

func _spawn_chest() -> void:
    if _dungeon_chest != null and is_instance_valid(_dungeon_chest):
        _dungeon_chest.queue_free()

    var chest_cell: Vector2i = _current_floor_data.get("chest_cell", Vector2i(-1, -1))
    if chest_cell.x < 0 or chest_cell.y < 0:
        _dungeon_chest = null
        return

    _dungeon_chest = DUNGEON_CHEST_SCENE.instantiate() as DungeonChest
    if _dungeon_chest == null:
        return

    _world_root.add_child(_dungeon_chest)
    _dungeon_chest.chest_tier = int(_current_floor_data.get("chest_tier", 1))
    _dungeon_chest.set_grid_position(chest_cell, _current_room.cell_size)
    _dungeon_chest.opened.connect(_on_dungeon_chest_opened)

func _spawn_dungeon_props() -> void:
    for prop_node in _dungeon_props:
        if is_instance_valid(prop_node):
            prop_node.queue_free()
    _dungeon_props.clear()

    var props_raw: Array = _current_floor_data.get("props", [])
    for prop_data in props_raw:
        if prop_data is not Dictionary:
            continue

        var cell_variant: Variant = prop_data.get("cell", Vector2i(-1, -1))
        if cell_variant is not Vector2i:
            continue
        var cell: Vector2i = cell_variant
        if cell.x < 0 or cell.y < 0:
            continue

        var prop_node: Node2D = DUNGEON_PROP_SCENE.instantiate() as Node2D
        if prop_node == null:
            continue

        var prop_type_name: String = String(prop_data.get("type", "torch"))
        prop_node.set("prop_type", _dungeon_prop_type_from_name(prop_type_name))
        _world_root.add_child(prop_node)
        if prop_node.has_method("set_grid_position"):
            prop_node.call("set_grid_position", cell, _current_room.cell_size)
        _dungeon_props.append(prop_node)

func _dungeon_prop_type_from_name(prop_name: String) -> int:
    match prop_name:
        "altar":
            return DUNGEON_PROP_TYPE_ALTAR
        "stairs":
            return DUNGEON_PROP_TYPE_STAIRS
        _:
            return DUNGEON_PROP_TYPE_TORCH

func _spawn_enemies() -> void:
    _enemies.clear()

    for index in range(min(_current_room.enemy_spawn_cells.size(), TEST_ENEMY_DATA.size())):
        var enemy := ENEMY_SCENE.instantiate()
        enemy.monster_data = _create_scaled_monster_data(TEST_ENEMY_DATA[index])
        enemy.name = "%s_%d" % [String(enemy.monster_data.id), index + 1]
        _world_root.add_child(enemy)
        enemy.set_grid_position(_current_room.enemy_spawn_cells[index])
        enemy.action_animation_finished.connect(_on_enemy_action_animation_finished)
        _enemies.append(enemy)

    _enemy = _enemies[0] if not _enemies.is_empty() else null

func _create_scaled_monster_data(base_monster: MonsterData) -> MonsterData:
    var monster_data: MonsterData = base_monster.duplicate(true) as MonsterData
    if monster_data == null:
        return base_monster

    var health_multiplier: float = float(_current_floor_data.get("enemy_health_multiplier", 1.0))
    var attack_multiplier: float = float(_current_floor_data.get("enemy_attack_multiplier", 1.0))
    monster_data.max_health = maxi(int(round(monster_data.max_health * health_multiplier)), 1)
    monster_data.attack = maxi(int(round(monster_data.attack * attack_multiplier)), 1)
    return monster_data

func _get_starter_loot_for_selected_class() -> Array[ItemData]:
    match GameManager.selected_class_id:
        &"archer":
            return [LONG_BOW_DATA, HEALTH_POTION_DATA]
        &"mage":
            return [APPRENTICE_STAFF_DATA, HEALTH_POTION_DATA]
        _:
            return [SHORT_SWORD_DATA, WOODEN_SHIELD_DATA]

func _get_starter_pet_for_selected_class() -> PetData:
    match GameManager.selected_class_id:
        &"archer":
            return RANGER_HAWK_PET_DATA
        &"mage":
            return ARCANE_FAIRY_PET_DATA
        _:
            return GUARDIAN_WHELP_PET_DATA

func _get_starter_mount_for_selected_class() -> MountData:
    match GameManager.selected_class_id:
        &"archer":
            return ROYAL_STAG_MOUNT_DATA
        &"mage":
            return ROYAL_STAG_MOUNT_DATA
        _:
            return IRON_WOLF_MOUNT_DATA

func _on_viewport_size_changed() -> void:
    _position_world_in_map.call_deferred()

func _position_world_in_map() -> void:
    if not is_instance_valid(_current_room):
        return

    var map_rect: Rect2 = _get_map_rect()
    if map_rect.size == Vector2.ZERO:
        _world_root.position = Vector2.ZERO
        return

    var room_size_in_pixels := Vector2(
        _current_room.room_size.x * _current_room.cell_size,
        _current_room.room_size.y * _current_room.cell_size
    )
    _world_root.position = map_rect.position + (map_rect.size - room_size_in_pixels) * 0.5

func _get_map_rect() -> Rect2:
    if is_instance_valid(_game_hud) and _game_hud.has_method("get_map_viewport_rect"):
        var map_rect: Variant = _game_hud.call("get_map_viewport_rect")
        if map_rect is Rect2:
            return map_rect
    return Rect2(Vector2.ZERO, get_viewport_rect().size)

func _is_cell_blocked(cell: Vector2i) -> bool:
    if _current_room.is_cell_blocked(cell):
        return true

    return _get_enemy_at_cell(cell) != null

func _is_cell_blocked_for_enemy(cell: Vector2i) -> bool:
    if _current_room.is_cell_blocked(cell):
        return true

    if is_instance_valid(_player) and _player.get_grid_position() == cell:
        return true

    return _get_enemy_at_cell(cell) != null

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
    for enemy in _get_living_enemies():
        if enemy.get_grid_position() == cell:
            return enemy

    return null

func _get_item_at_cell(cell: Vector2i) -> Node:
    for world_item in _ground_items:
        if is_instance_valid(world_item) and world_item.get_grid_position() == cell:
            return world_item

    return null

func _collect_ground_item_under_player() -> bool:
    if not is_instance_valid(_player):
        return false

    if _try_open_chest_under_player():
        return true

    var world_item: Node = _get_item_at_cell(_player.get_grid_position())
    if world_item == null:
        return false
    if not world_item.pickup(_player):
        return false

    _ground_items.erase(world_item)
    return true

func _try_open_chest_under_player() -> bool:
    if not is_instance_valid(_dungeon_chest):
        return false
    if _dungeon_chest.is_open():
        return false
    if _dungeon_chest.get_grid_position() != _player.get_grid_position():
        return false
    return _dungeon_chest.try_open()

func _get_living_enemies() -> Array[Node]:
    var living_enemies: Array[Node] = []

    for enemy in _enemies:
        if is_instance_valid(enemy) and enemy.is_alive():
            living_enemies.append(enemy)

    return living_enemies

func _is_adjacent(first_cell: Vector2i, second_cell: Vector2i) -> bool:
    var delta := first_cell - second_cell
    return absi(delta.x) + absi(delta.y) == 1

func _get_enemy_step_towards_player(enemy_cell: Vector2i, player_cell: Vector2i) -> Vector2i:
    var candidates: Array[Vector2i] = []
    var delta := player_cell - enemy_cell

    if absi(delta.x) >= absi(delta.y):
        candidates.append(Vector2i(signi(delta.x), 0))
        candidates.append(Vector2i(0, signi(delta.y)))
    else:
        candidates.append(Vector2i(0, signi(delta.y)))
        candidates.append(Vector2i(signi(delta.x), 0))

    for candidate in candidates:
        if candidate == Vector2i.ZERO:
            continue
        if not _is_cell_blocked_for_enemy(enemy_cell + candidate):
            return candidate

    return Vector2i.ZERO

func _on_player_turn_started(_turn_number: int) -> void:
    if is_instance_valid(_player) and _player.has_method("on_new_player_turn"):
        _player.on_new_player_turn()
    EventBus.player_turn_ready.emit()
    if _auto_dungeon_enabled:
        _run_auto_player_action.call_deferred()

func _on_enemy_turn_started(_turn_number: int) -> void:
    _enemy_turn_queue = _get_living_enemies()
    _active_enemy = null
    _active_enemy_actions_remaining = 0
    _process_next_enemy_turn.call_deferred()

func _process_next_enemy_turn() -> void:
    if TurnManager.phase != TurnManager.Phase.ENEMY_TURN:
        return

    if not is_instance_valid(_player) or not _player.is_alive():
        TurnManager.finish_enemy_turn()
        return

    while not _enemy_turn_queue.is_empty():
        var next_enemy: Node = _enemy_turn_queue.pop_front()
        if not is_instance_valid(next_enemy) or not next_enemy.is_alive():
            continue

        _active_enemy = next_enemy
        _active_enemy_actions_remaining = _get_enemy_actions_per_turn(next_enemy)
        _resolve_single_enemy_turn(next_enemy)
        return

    _active_enemy = null
    _active_enemy_actions_remaining = 0
    TurnManager.finish_enemy_turn()

func _resolve_single_enemy_turn(enemy: Node) -> void:
    if not is_instance_valid(enemy) or not enemy.is_alive():
        _process_next_enemy_turn.call_deferred()
        return

    if not is_instance_valid(_player) or not _player.is_alive():
        TurnManager.finish_enemy_turn()
        return

    var enemy_cell: Vector2i = enemy.get_grid_position()
    var player_cell: Vector2i = _player.get_grid_position()

    if _is_adjacent(enemy_cell, player_cell):
        _active_enemy_actions_remaining = 0
        enemy.try_attack(_player)
        return

    var moved: bool = false
    if _active_enemy_actions_remaining > 0:
        var step := _get_enemy_step_for_behavior(enemy, enemy_cell, player_cell)
        if step != Vector2i.ZERO and enemy.try_move_direction(step, Callable(self, "_is_cell_blocked_for_enemy")):
            _active_enemy_actions_remaining -= 1
            moved = true

    if moved:
        return

    EventBus.action_resolved.emit(enemy.display_name, &"wait")
    _advance_enemy_turn_queue()

func _on_enemy_action_animation_finished() -> void:
    if is_instance_valid(_active_enemy) and _active_enemy.is_alive() and _active_enemy_actions_remaining > 0:
        _resolve_single_enemy_turn(_active_enemy)
        return

    _advance_enemy_turn_queue()

func _advance_enemy_turn_queue() -> void:
    _active_enemy = null
    _active_enemy_actions_remaining = 0
    _process_next_enemy_turn.call_deferred()

func _get_enemy_step_for_behavior(enemy: Node, enemy_cell: Vector2i, player_cell: Vector2i) -> Vector2i:
    if enemy == null or enemy.monster_data == null:
        return _get_enemy_step_towards_player(enemy_cell, player_cell)

    var distance_to_player := _get_manhattan_distance(enemy_cell, player_cell)

    match enemy.monster_data.behavior:
        MonsterData.BehaviorType.PASSIVE:
            return Vector2i.ZERO
        MonsterData.BehaviorType.SKIRMISHER:
            if distance_to_player > 2:
                return _get_enemy_step_towards_player(enemy_cell, player_cell)
            return Vector2i.ZERO
        _:
            return _get_enemy_step_towards_player(enemy_cell, player_cell)

func _get_enemy_actions_per_turn(enemy: Node) -> int:
    if enemy == null or enemy.monster_data == null:
        return 1

    return 2 if enemy.monster_data.speed >= 4 else 1

func _get_manhattan_distance(from_cell: Vector2i, to_cell: Vector2i) -> int:
    var delta := to_cell - from_cell
    return absi(delta.x) + absi(delta.y)

func _on_player_action_animation_finished() -> void:
    _collect_ground_item_under_player()
    TurnManager.resolve_player_action(true)

func _on_actor_moved(actor_name: String, from_cell: Vector2i, to_cell: Vector2i) -> void:
    print("%s moveu de %s para %s" % [actor_name, from_cell, to_cell])

func _on_actor_attacked(attacker_name: String, target_name: String, damage: int) -> void:
    print("%s atacou %s causando %d de dano" % [attacker_name, target_name, damage])

func _on_actor_damaged(actor_name: String, amount: int, current_health: int, max_health: int) -> void:
    print("%s recebeu %d de dano (%d/%d)" % [actor_name, amount, current_health, max_health])

func _on_actor_died(actor_name: String) -> void:
    print("%s morreu" % actor_name)

func _on_skill_used(actor_name: String, _skill_id: StringName, skill_name: String) -> void:
    print("%s usou a habilidade %s" % [actor_name, skill_name])

func _on_item_picked_up(actor_name: String, item_name: String, quantity: int) -> void:
    print("%s coletou %s x%d" % [actor_name, item_name, quantity])

func _on_item_used(actor_name: String, item_name: String, quantity: int) -> void:
    print("%s usou %s x%d" % [actor_name, item_name, quantity])

func _on_inventory_changed(actor_name: String, item_id: StringName, quantity: int) -> void:
    print("Inventario de %s: %s = %d" % [actor_name, item_id, quantity])

func _on_inventory_item_requested(item_id: StringName) -> void:
    if not is_instance_valid(_player):
        return
    if TurnManager.phase != TurnManager.Phase.PLAYER_INPUT:
        return
    if not TurnManager.begin_resolution():
        return

    var consumed_turn: bool = false
    if _player.try_equip_item_by_id(item_id):
        print("%s equipou %s via HUD" % [String(_player.display_name), item_id])
        consumed_turn = true
    elif _player.try_use_consumable(item_id):
        print("%s usou %s via HUD" % [String(_player.display_name), item_id])
        consumed_turn = true

    TurnManager.resolve_player_action(consumed_turn)

func _on_inventory_unequip_requested(slot: int) -> void:
    if not is_instance_valid(_player):
        return
    if TurnManager.phase != TurnManager.Phase.PLAYER_INPUT:
        return
    if not TurnManager.begin_resolution():
        return

    var consumed_turn: bool = false
    if _player.try_unequip_slot(slot):
        print("%s removeu item do slot %d via HUD" % [String(_player.display_name), slot])
        consumed_turn = true

    TurnManager.resolve_player_action(consumed_turn)

func _on_equipment_changed(actor_name: String, slot: int, item_id: StringName) -> void:
    print("Equipamento de %s: slot %d = %s" % [actor_name, slot, item_id])

func _on_pet_changed(actor_name: String, pet_id: StringName) -> void:
    print("Pet ativo de %s: %s" % [actor_name, pet_id])

func _on_mount_changed(actor_name: String, mount_id: StringName) -> void:
    print("Montaria ativa de %s: %s" % [actor_name, mount_id])

func _on_chest_opened(actor_name: String, floor_level: int, chest_tier: int, item_name: String) -> void:
    print("%s abriu o bau do floor %d (tier %d) e recebeu %s" % [actor_name, floor_level, chest_tier, item_name])

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

func _is_swap_pet_event(event: InputEvent) -> bool:
    if event is not InputEventKey:
        return false

    var key_event := event as InputEventKey
    return key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_P

func _is_swap_mount_event(event: InputEvent) -> bool:
    if event is not InputEventKey:
        return false

    var key_event := event as InputEventKey
    return key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_M

func _cycle_player_pet() -> void:
    if not is_instance_valid(_player) or AVAILABLE_PETS.is_empty():
        return
    _active_pet_index = (_active_pet_index + 1) % AVAILABLE_PETS.size()
    var pet_data: PetData = AVAILABLE_PETS[_active_pet_index]
    _player.equip_pet(pet_data)

func _cycle_player_mount() -> void:
    if not is_instance_valid(_player) or AVAILABLE_MOUNTS.is_empty():
        return
    _active_mount_index = (_active_mount_index + 1) % AVAILABLE_MOUNTS.size()
    var mount_data: MountData = AVAILABLE_MOUNTS[_active_mount_index]
    _player.equip_mount(mount_data)

func _skill_slot_from_event(event: InputEvent) -> int:
    if event is not InputEventKey:
        return -1

    var key_event := event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return -1

    match key_event.physical_keycode:
        KEY_1:
            return 0
        KEY_2:
            return 1
        KEY_3:
            return 2
        KEY_4:
            return 3
        _:
            return -1

func _on_dungeon_requested() -> void:
    _build_auto_path_from_floor_data()
    _auto_dungeon_enabled = not _auto_path.is_empty()
    if _auto_dungeon_enabled and TurnManager.phase == TurnManager.Phase.PLAYER_INPUT:
        _run_auto_player_action.call_deferred()

func _build_auto_path_from_floor_data() -> void:
    _auto_path.clear()
    _auto_path_index = 0
    var raw_path: Array = _current_floor_data.get("path", [])
    for cell in raw_path:
        if cell is Vector2i:
            _auto_path.append(cell)

func _on_dungeon_chest_opened(chest: DungeonChest) -> void:
    if not is_instance_valid(_player) or chest == null:
        return

    var chest_tier: int = chest.chest_tier
    var rewarded_item: ItemData = _roll_chest_loot(chest_tier)
    if rewarded_item == null:
        return

    if not _player.add_item(rewarded_item, 1):
        return

    EventBus.chest_opened.emit(String(_player.display_name), maxi(GameManager.current_floor, 1), chest_tier, String(rewarded_item.display_name))

func _roll_chest_loot(chest_tier: int) -> ItemData:
    var class_id: StringName = GameManager.selected_class_id
    var pool: Array[ItemData] = []

    match class_id:
        &"archer":
            pool = [LONG_BOW_DATA, HEALTH_POTION_DATA]
        &"mage":
            pool = [APPRENTICE_STAFF_DATA, HEALTH_POTION_DATA]
        _:
            pool = [SHORT_SWORD_DATA, WOODEN_SHIELD_DATA, HEALTH_POTION_DATA]

    pool.append(LEATHER_GLOVES_DATA)
    pool.append(LEATHER_BOOTS_DATA)
    if chest_tier >= 2:
        pool.append(LEATHER_HELMET_DATA)
        pool.append(LEATHER_ARMOR_DATA)
    if chest_tier >= 3:
        pool.append(FLOOR_KEY_DATA)

    var index: int = int((GameManager.current_floor + chest_tier) % pool.size())
    return pool[index]

func _run_auto_player_action() -> void:
    if not _auto_dungeon_enabled:
        return
    if TurnManager.phase != TurnManager.Phase.PLAYER_INPUT:
        return
    if not is_instance_valid(_player) or not _player.is_alive():
        return
    if not TurnManager.begin_resolution():
        return

    var adjacent_target: Node = _get_adjacent_attack_target()
    if adjacent_target != null:
        if _player.try_use_active_skill_slot(0, adjacent_target):
            return
        if _player.try_attack(adjacent_target):
            return
        TurnManager.resolve_player_action(false)
        return

    var direction: Vector2i = _get_next_auto_direction()
    if direction == Vector2i.ZERO:
        _auto_dungeon_enabled = false
        TurnManager.resolve_player_action(false)
        return

    var moved: bool = _player.try_move_direction(direction, Callable(self, "_is_cell_blocked"))
    if not moved:
        TurnManager.resolve_player_action(false)

func _get_next_auto_direction() -> Vector2i:
    var player_cell: Vector2i = _player.get_grid_position()

    while _auto_path_index < _auto_path.size() and _auto_path[_auto_path_index] == player_cell:
        _auto_path_index += 1

    if _auto_path_index >= _auto_path.size():
        return Vector2i.ZERO

    var next_cell: Vector2i = _auto_path[_auto_path_index]
    var delta: Vector2i = next_cell - player_cell
    if delta == Vector2i.ZERO:
        return Vector2i.ZERO

    if absi(delta.x) >= absi(delta.y):
        return Vector2i(signi(delta.x), 0)
    return Vector2i(0, signi(delta.y))
