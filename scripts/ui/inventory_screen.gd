extends Control

@onready var equipment_container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/HBoxContainer/LeftPanel/EquipmentContainer
@onready var inventory_grid: GridContainer = $CenterContainer/PanelContainer/MarginContainer/HBoxContainer/RightPanel/ScrollContainer/InventoryGrid
@onready var stats_label: RichTextLabel = $CenterContainer/PanelContainer/MarginContainer/HBoxContainer/LeftPanel/StatsLabel

var _player: Node

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    hide()

func open(player: Node) -> void:
    _player = player
    get_tree().paused = true
    show()
    refresh_ui()

func close() -> void:
    hide()
    get_tree().paused = false
    _player = null

func refresh_ui() -> void:
    if not is_instance_valid(_player):
        return

    _refresh_equipment()
    _refresh_inventory()
    _refresh_stats()

func _refresh_equipment() -> void:
    for child in equipment_container.get_children():
        child.queue_free()

    if not _player.has_node("Equipment"):
        return

    var equipment: Node = _player.get_node("Equipment")
    for slot_id in range(1, 7): # ItemData.EquipSlot.HELMET to WEAPON/SHIELD
        var slot_name: String = "Slot " + str(slot_id)
        match slot_id:
            1: slot_name = "Helmet"
            2: slot_name = "Armor"
            3: slot_name = "Gloves"
            4: slot_name = "Boots"
            5: slot_name = "Shield"
            6: slot_name = "Weapon"

        var item: ItemData = equipment.get_equipped(slot_id)
        var btn := Button.new()
        btn.custom_minimum_size = Vector2(160, 40)
        
        if item != null:
            btn.text = "%s [%s]" % [slot_name, item.display_name]
            btn.icon = item.icon
            btn.add_theme_color_override("font_color", item.get_rarity_color())
            btn.pressed.connect(func(): _unequip_item(slot_id))
        else:
            btn.text = "[Empty " + slot_name + "]"
        
        equipment_container.add_child(btn)

func _refresh_inventory() -> void:
    for child in inventory_grid.get_children():
        child.queue_free()

    if not _player.has_node("Inventory"):
        return

    var inventory: Node = _player.get_node("Inventory")
    for entry in inventory.get_entries():
        var item: ItemData = entry["data"]
        if not item.is_equipment():
            continue # Show only equipment for now, or everything? Let's show all.
            
        var btn := Button.new()
        btn.custom_minimum_size = Vector2(40, 40)
        btn.tooltip_text = "%s\nATK: +%d | DEF: +%d" % [item.display_name, item.attack_bonus, item.defense_bonus]
        if item.icon:
            btn.icon = item.icon
            btn.expand_icon = true
        else:
            btn.text = "?"
            
        # Optional: Add border color based on rarity
        var style := StyleBoxFlat.new()
        style.bg_color = Color(0.1, 0.1, 0.1)
        style.border_width_bottom = 2
        style.border_color = item.get_rarity_color() if item.has_method("get_rarity_color") else Color.GRAY
        btn.add_theme_stylebox_override("normal", style)
        
        btn.pressed.connect(func(): _equip_item_from_inventory(item))
        inventory_grid.add_child(btn)

func _refresh_stats() -> void:
    if not is_instance_valid(_player):
        return
    
    var text := "[b]Hero Status[/b]\n"
    text += "Level: 1\n"
    text += "Attack: %d\n" % _player.attack_power
    text += "Defense: %d\n" % _player.defense_power
    text += "Health: %d\n" % _player.health.current_health
    
    stats_label.text = text

func _unequip_item(slot_id: int) -> void:
    if not is_instance_valid(_player):
        return
    
    var equip_comp: Node = _player.get_node("Equipment")
    var inv_comp: Node = _player.get_node("Inventory")
    
    var item: ItemData = equip_comp.unequip(slot_id)
    if item != null:
        inv_comp.add_item(item, 1)
        # We need player to recalculate stats!
        if _player.has_method("_recalculate_combat_stats"):
            _player._recalculate_combat_stats()
            
    refresh_ui()

func _equip_item_from_inventory(item: ItemData) -> void:
    if not is_instance_valid(_player) or not item.is_equipment():
        return
        
    var equip_comp: Node = _player.get_node("Equipment")
    var inv_comp: Node = _player.get_node("Inventory")
    
    # Check if we can equip
    if not equip_comp.can_equip(item, _player.class_data.id if _player.class_data else &""):
        return
        
    # Remove from inventory
    var key = item.instance_id if not item.stackable else item.id
    inv_comp.consume_item(key, 1)
    
    # If something was already equipped, put it back in inventory
    var old_item: ItemData = equip_comp.unequip(item.equip_slot)
    if old_item != null:
        inv_comp.add_item(old_item, 1)
        
    # Equip new
    equip_comp.equip(item, _player.class_data.id if _player.class_data else &"")
    
    if _player.has_method("_recalculate_combat_stats"):
        _player._recalculate_combat_stats()
        
    refresh_ui()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel") and visible:
        close()
        get_viewport().set_input_as_handled()
