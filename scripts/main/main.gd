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
const COMBAT_CONTROLLER_SCRIPT := preload("res://scripts/main/combat_controller.gd")
const ENEMY_AI_CONTROLLER_SCRIPT := preload("res://scripts/main/enemy_ai_controller.gd")
const AUTO_DUNGEON_CONTROLLER_SCRIPT := preload("res://scripts/main/auto_dungeon_controller.gd")
const LOOT_CONTROLLER_SCRIPT := preload("res://scripts/main/loot_controller.gd")
const GAME_OVER_SCENE_PATH := "res://scenes/ui/game_over_screen.tscn"
const INVENTORY_SCREEN_SCENE := preload("res://scenes/ui/inventory_screen.tscn")
const FLOATING_NUMBER_SCENE := preload("res://scenes/ui/floating_number.tscn")
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
const PLAYER_DAMAGE_SHAKE_DURATION: float = 0.1
const PLAYER_DAMAGE_SHAKE_OFFSET_MIN: float = 2.0
const PLAYER_DAMAGE_SHAKE_OFFSET_MAX: float = 3.0

var _current_room: Node
var _player: Node
var _enemy: Node
var _enemies: Array[Node] = []
var _ground_items: Array[Node] = []
var _current_floor_data: Dictionary = {}
var _dungeon_chest: DungeonChest
var _dungeon_props: Array[Node] = []
var _active_pet_index: int = 0
var _active_mount_index: int = 0
var _pending_stairs_check: bool = false
var _world_root_base_position: Vector2 = Vector2.ZERO
var _world_root_shake_offset: Vector2 = Vector2.ZERO
var _world_root_shake_tween: Tween
var _combat_controller
var _enemy_ai_controller
var _auto_dungeon_controller
var _loot_controller
var _inventory_screen: Node

@onready var _world_root: Node2D = $WorldRoot
@onready var _game_hud: Node = $GameHUD

func _ready() -> void:
    _setup_controllers()
    
    _inventory_screen = INVENTORY_SCREEN_SCENE.instantiate()
    add_child(_inventory_screen)
    
    TurnManager.player_turn_started.connect(_on_player_turn_started)
    TurnManager.enemy_turn_started.connect(_on_enemy_turn_started)
    get_viewport().size_changed.connect(_on_viewport_size_changed)
    if is_instance_valid(_game_hud):
        if _game_hud.has_signal("dungeon_requested"):
            _game_hud.dungeon_requested.connect(_on_dungeon_requested)
        if _game_hud.has_signal("inventory_popup_requested"):
            _game_hud.inventory_popup_requested.connect(_on_inventory_popup_requested)
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
    EventBus.player_died.connect(_on_player_died)

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

func _process(_delta: float) -> void:
    if _auto_dungeon_controller == null:
        return
    if not _auto_dungeon_controller.is_enabled():
        return
    if TurnManager.phase != TurnManager.Phase.PLAYER_INPUT:
        return
    _run_auto_player_action()

func _setup_controllers() -> void:
    _combat_controller = COMBAT_CONTROLLER_SCRIPT.new()
    _combat_controller.configure(ADJACENT_CELLS)

    _enemy_ai_controller = ENEMY_AI_CONTROLLER_SCRIPT.new()
    _auto_dungeon_controller = AUTO_DUNGEON_CONTROLLER_SCRIPT.new()

    _loot_controller = LOOT_CONTROLLER_SCRIPT.new()
    _loot_controller.configure({
        "short_sword": SHORT_SWORD_DATA,
        "wooden_shield": WOODEN_SHIELD_DATA,
        "long_bow": LONG_BOW_DATA,
        "apprentice_staff": APPRENTICE_STAFF_DATA,
        "health_potion": HEALTH_POTION_DATA,
        "floor_key": FLOOR_KEY_DATA,
        "leather_helmet": LEATHER_HELMET_DATA,
        "leather_armor": LEATHER_ARMOR_DATA,
        "leather_gloves": LEATHER_GLOVES_DATA,
        "leather_boots": LEATHER_BOOTS_DATA,
    })

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
    var starter_loot: Array[ItemData] = _get_starter_loot_for_selected_class()
    _loot_controller.spawn_items(_world_root, WORLD_ITEM_SCENE, _current_room, starter_loot, _ground_items)

func _spawn_chest() -> void:
    _dungeon_chest = _loot_controller.spawn_chest(
        _world_root,
        DUNGEON_CHEST_SCENE,
        _current_floor_data,
        _current_room,
        _dungeon_chest,
        Callable(self, "_on_dungeon_chest_opened")
    )

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
        _set_world_root_base_position(Vector2.ZERO)
        return

    var room_size_in_pixels := Vector2(
        _current_room.room_size.x * _current_room.cell_size,
        _current_room.room_size.y * _current_room.cell_size
    )
    _set_world_root_base_position(map_rect.position + (map_rect.size - room_size_in_pixels) * 0.5)

func _set_world_root_base_position(base_position: Vector2) -> void:
    _world_root_base_position = base_position
    _apply_world_root_position()

func _set_world_root_shake_offset(shake_offset: Vector2) -> void:
    _world_root_shake_offset = shake_offset
    _apply_world_root_position()

func _apply_world_root_position() -> void:
    if not is_instance_valid(_world_root):
        return
    _world_root.position = _world_root_base_position + _world_root_shake_offset

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

func _get_enemy_at_cell(cell: Vector2i) -> Node:
    for enemy in _get_living_enemies():
        if enemy.get_grid_position() == cell:
            return enemy

    return null

func _try_player_melee_attack() -> bool:
    return _combat_controller.try_player_melee_attack(_player, _enemies)

func _is_boss_room_locked() -> bool:
    if _current_floor_data.get("is_boss_room", false):
        return not _get_living_enemies().is_empty()
    return false

func _collect_ground_item_under_player() -> bool:
    if _is_boss_room_locked():
        return false
    return _loot_controller.collect_ground_item_under_player(_player, _ground_items, _dungeon_chest)

func _try_transition_floor_under_player() -> bool:
    if _is_boss_room_locked():
        return false
    if not is_instance_valid(_player):
        return false

    var stairs_cell: Vector2i = _get_stairs_cell_from_floor_data()
    if stairs_cell.x < 0 or stairs_cell.y < 0:
        return false
    if _player.get_grid_position() != stairs_cell:
        return false

    GameManager.go_to_next_floor()
    if GameManager.state != GameManager.State.PLAYING:
        return true

    EventBus.level_up.emit(maxi(GameManager.current_floor, 1))
    _respawn_floor_from_service()
    return true

func _get_stairs_cell_from_floor_data() -> Vector2i:
    var props_raw: Array = _current_floor_data.get("props", [])
    for prop_data in props_raw:
        if prop_data is not Dictionary:
            continue

        if String(prop_data.get("type", "")) != "stairs":
            continue

        var cell_variant: Variant = prop_data.get("cell", Vector2i(-1, -1))
        if cell_variant is Vector2i:
            return cell_variant

    return Vector2i(-1, -1)

func _respawn_floor_from_service() -> void:
    _clear_current_floor_entities()
    _apply_floor_data_to_room()
    if is_instance_valid(_current_room):
        _current_room.queue_redraw()

    _spawn_items()
    _spawn_chest()
    _spawn_dungeon_props()
    _spawn_enemies()
    if is_instance_valid(_player) and is_instance_valid(_current_room):
        _player.set_grid_position(_current_room.player_spawn_cell)

    _build_auto_path_from_floor_data()
    _position_world_in_map.call_deferred()

func _clear_current_floor_entities() -> void:
    for world_item in _ground_items:
        if is_instance_valid(world_item):
            world_item.queue_free()
    _ground_items.clear()

    if is_instance_valid(_dungeon_chest):
        _dungeon_chest.queue_free()
    _dungeon_chest = null

    for prop_node in _dungeon_props:
        if is_instance_valid(prop_node):
            prop_node.queue_free()
    _dungeon_props.clear()

    for enemy in _enemies:
        if is_instance_valid(enemy):
            enemy.queue_free()
    _enemies.clear()
    _enemy = null
    _enemy_ai_controller.clear_state()

func _get_living_enemies() -> Array[Node]:
    var living_enemies: Array[Node] = []

    for enemy in _enemies:
        if is_instance_valid(enemy) and enemy.is_alive():
            living_enemies.append(enemy)

    return living_enemies

func _on_player_turn_started(_turn_number: int) -> void:
    if is_instance_valid(_player) and _player.has_method("on_new_player_turn"):
        _player.on_new_player_turn()
    EventBus.player_turn_ready.emit()
    if _auto_dungeon_controller.is_enabled() and TurnManager.phase == TurnManager.Phase.PLAYER_INPUT:
        _run_auto_player_action()

func _on_enemy_turn_started(_turn_number: int) -> void:
    _enemy_ai_controller.begin_enemy_turn(_get_living_enemies(), Callable(self, "_process_next_enemy_turn"))

func _process_next_enemy_turn() -> void:
    _enemy_ai_controller.process_next_enemy_turn(
        _player,
        Callable(self, "_is_cell_blocked_for_enemy"),
        Callable(self, "_process_next_enemy_turn")
    )

func _on_enemy_action_animation_finished() -> void:
    _enemy_ai_controller.on_enemy_action_animation_finished(
        _player,
        Callable(self, "_is_cell_blocked_for_enemy"),
        Callable(self, "_process_next_enemy_turn")
    )

func _on_player_action_animation_finished() -> void:
    var moved_this_action: bool = _pending_stairs_check
    _pending_stairs_check = false
    if is_instance_valid(_player) and _player.has_method("tick_cooldowns_and_mana"):
        _player.tick_cooldowns_and_mana()
    _collect_ground_item_under_player()
    if moved_this_action and _try_transition_floor_under_player():
        if GameManager.state != GameManager.State.PLAYING:
            return
    TurnManager.resolve_player_action(true)

func _on_actor_moved(actor_name: String, from_cell: Vector2i, to_cell: Vector2i) -> void:
    print("%s moveu de %s para %s" % [actor_name, from_cell, to_cell])

func _on_actor_attacked(attacker_name: String, target_name: String, damage: int) -> void:
    print("%s atacou %s causando %d de dano" % [attacker_name, target_name, damage])

func _on_actor_damaged(actor_name: String, amount: int, current_health: int, max_health: int) -> void:
    if _is_player_actor_name(actor_name):
        _apply_player_damage_screen_shake()
    _spawn_floating_damage_number(actor_name, amount, false)
    print("%s recebeu %d de dano (%d/%d)" % [actor_name, amount, current_health, max_health])

func _is_player_actor_name(actor_name: String) -> bool:
    if not is_instance_valid(_player):
        return false
    return String(_player.display_name) == actor_name or String(_player.name) == actor_name

func _apply_player_damage_screen_shake() -> void:
    if not is_instance_valid(_world_root):
        return

    if is_instance_valid(_world_root_shake_tween):
        _world_root_shake_tween.kill()

    var shake_x: float = randf_range(PLAYER_DAMAGE_SHAKE_OFFSET_MIN, PLAYER_DAMAGE_SHAKE_OFFSET_MAX)
    var shake_y: float = randf_range(PLAYER_DAMAGE_SHAKE_OFFSET_MIN, PLAYER_DAMAGE_SHAKE_OFFSET_MAX)
    if randf() < 0.5:
        shake_x *= -1.0
    if randf() < 0.5:
        shake_y *= -1.0

    _set_world_root_shake_offset(Vector2(shake_x, shake_y))
    _world_root_shake_tween = create_tween()
    _world_root_shake_tween.tween_method(
        Callable(self, "_set_world_root_shake_offset"),
        _world_root_shake_offset,
        Vector2.ZERO,
        PLAYER_DAMAGE_SHAKE_DURATION
    ).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    _world_root_shake_tween.finished.connect(_on_world_root_shake_finished)

func _on_world_root_shake_finished() -> void:
    _set_world_root_shake_offset(Vector2.ZERO)
    _world_root_shake_tween = null

func _spawn_floating_damage_number(actor_name: String, amount: int, is_critical: bool) -> void:
    if amount <= 0:
        return

    var actor_node: Node2D = _find_actor_node_by_name(actor_name)
    if not is_instance_valid(actor_node):
        return

    var floating_number: Node = FLOATING_NUMBER_SCENE.instantiate()
    if floating_number == null:
        return

    add_child(floating_number)

    var cell_size: int = 32
    if is_instance_valid(_current_room):
        cell_size = int(_current_room.cell_size)

    var popup_anchor: Vector2 = actor_node.global_position + Vector2(float(cell_size) * 0.5 - 32.0, -20.0)
    if floating_number is Control:
        var floating_control := floating_number as Control
        floating_control.global_position = popup_anchor

    if floating_number.has_method("setup"):
        floating_number.call("setup", amount, is_critical)

func _find_actor_node_by_name(actor_name: String) -> Node2D:
    if is_instance_valid(_player):
        if String(_player.display_name) == actor_name or String(_player.name) == actor_name:
            return _player as Node2D

    for enemy in _enemies:
        if not is_instance_valid(enemy):
            continue
        if String(enemy.display_name) == actor_name or String(enemy.name) == actor_name:
            return enemy as Node2D

    return null

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

func _on_inventory_popup_requested() -> void:
    if is_instance_valid(_player) and is_instance_valid(_inventory_screen):
        _inventory_screen.open(_player)

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

func _on_player_died() -> void:
    _auto_dungeon_controller.clear_state()
    GameManager.end_run()
    var scene_manager: Node = get_node_or_null("/root/SceneManager")
    if scene_manager != null and scene_manager.has_method("change_scene"):
        scene_manager.call("change_scene", GAME_OVER_SCENE_PATH)
        return
    get_tree().change_scene_to_file(GAME_OVER_SCENE_PATH)

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

func _on_dungeon_requested() -> void:
    var auto_enabled: bool = _auto_dungeon_controller.on_dungeon_requested(_current_floor_data)
    if auto_enabled and TurnManager.phase == TurnManager.Phase.PLAYER_INPUT:
        _run_auto_player_action()

func _build_auto_path_from_floor_data() -> void:
    _auto_dungeon_controller.refresh_path_from_floor_data(_current_floor_data)

func _on_dungeon_chest_opened(chest: DungeonChest) -> void:
    _loot_controller.on_dungeon_chest_opened(_player, chest)

func _run_auto_player_action() -> void:
    var moved: bool = _auto_dungeon_controller.run_auto_player_action(
        _player,
        _enemies,
        _combat_controller,
        Callable(self, "_is_cell_blocked")
    )
    if moved:
        _pending_stairs_check = true
