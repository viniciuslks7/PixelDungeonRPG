class_name LootController
extends RefCounted

var _short_sword_data: ItemData
var _wooden_shield_data: ItemData
var _long_bow_data: ItemData
var _apprentice_staff_data: ItemData
var _health_potion_data: ItemData
var _floor_key_data: ItemData
var _leather_helmet_data: ItemData
var _leather_armor_data: ItemData
var _leather_gloves_data: ItemData
var _leather_boots_data: ItemData

func configure(loot_config: Dictionary) -> void:
    _short_sword_data = loot_config.get("short_sword") as ItemData
    _wooden_shield_data = loot_config.get("wooden_shield") as ItemData
    _long_bow_data = loot_config.get("long_bow") as ItemData
    _apprentice_staff_data = loot_config.get("apprentice_staff") as ItemData
    _health_potion_data = loot_config.get("health_potion") as ItemData
    _floor_key_data = loot_config.get("floor_key") as ItemData
    _leather_helmet_data = loot_config.get("leather_helmet") as ItemData
    _leather_armor_data = loot_config.get("leather_armor") as ItemData
    _leather_gloves_data = loot_config.get("leather_gloves") as ItemData
    _leather_boots_data = loot_config.get("leather_boots") as ItemData

func spawn_items(
    world_root: Node2D,
    world_item_scene: PackedScene,
    current_room: Node,
    starter_loot: Array[ItemData],
    ground_items: Array[Node]
) -> void:
    ground_items.clear()

    for index in range(min(current_room.item_spawn_cells.size(), starter_loot.size())):
        var world_item := world_item_scene.instantiate()
        world_item.item_data = starter_loot[index]
        world_item.name = "%s_%d" % [String(world_item.item_data.id), index + 1]
        world_root.add_child(world_item)
        world_item.set_grid_position(current_room.item_spawn_cells[index], current_room.cell_size)
        ground_items.append(world_item)

func spawn_chest(
    world_root: Node2D,
    chest_scene: PackedScene,
    current_floor_data: Dictionary,
    current_room: Node,
    current_chest: DungeonChest,
    chest_opened_callback: Callable
) -> DungeonChest:
    if current_chest != null and is_instance_valid(current_chest):
        current_chest.queue_free()

    var chest_cell: Vector2i = current_floor_data.get("chest_cell", Vector2i(-1, -1))
    if chest_cell.x < 0 or chest_cell.y < 0:
        return null

    var dungeon_chest := chest_scene.instantiate() as DungeonChest
    if dungeon_chest == null:
        return null

    world_root.add_child(dungeon_chest)
    dungeon_chest.chest_tier = int(current_floor_data.get("chest_tier", 1))
    dungeon_chest.set_grid_position(chest_cell, current_room.cell_size)
    dungeon_chest.opened.connect(chest_opened_callback)
    return dungeon_chest

func collect_ground_item_under_player(player: Node, ground_items: Array[Node], dungeon_chest: DungeonChest) -> bool:
    if not is_instance_valid(player):
        return false

    if try_open_chest_under_player(player, dungeon_chest):
        return true

    var world_item: Node = get_item_at_cell(ground_items, player.get_grid_position())
    if world_item == null:
        return false
    if not world_item.pickup(player):
        return false

    ground_items.erase(world_item)
    return true

func try_open_chest_under_player(player: Node, dungeon_chest: DungeonChest) -> bool:
    if not is_instance_valid(dungeon_chest):
        return false
    if dungeon_chest.is_open():
        return false
    if dungeon_chest.get_grid_position() != player.get_grid_position():
        return false
    return dungeon_chest.try_open()

func on_dungeon_chest_opened(player: Node, chest: DungeonChest) -> void:
    if not is_instance_valid(player) or chest == null:
        return

    var chest_tier: int = chest.chest_tier
    var rewarded_item: ItemData = roll_chest_loot(chest_tier)
    if rewarded_item == null:
        return
    if not player.add_item(rewarded_item, 1):
        return

    EventBus.chest_opened.emit(
        String(player.display_name),
        maxi(GameManager.current_floor, 1),
        chest_tier,
        String(rewarded_item.display_name)
    )

func roll_chest_loot(chest_tier: int) -> ItemData:
    var class_id: StringName = GameManager.selected_class_id
    var pool: Array[ItemData] = []

    match class_id:
        &"archer":
            pool = [_long_bow_data, _health_potion_data]
        &"mage":
            pool = [_apprentice_staff_data, _health_potion_data]
        _:
            pool = [_short_sword_data, _wooden_shield_data, _health_potion_data]

    pool.append(_leather_gloves_data)
    pool.append(_leather_boots_data)
    if chest_tier >= 2:
        pool.append(_leather_helmet_data)
        pool.append(_leather_armor_data)
    if chest_tier >= 3:
        pool.append(_floor_key_data)

    var index: int = int(randi() % pool.size())
    return pool[index]

func get_item_at_cell(ground_items: Array[Node], cell: Vector2i) -> Node:
    for world_item in ground_items:
        if is_instance_valid(world_item) and world_item.get_grid_position() == cell:
            return world_item
    return null
