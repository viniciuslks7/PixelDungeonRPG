extends CanvasLayer

signal dungeon_requested
signal inventory_item_requested(item_id: StringName)
signal inventory_unequip_requested(slot: int)
signal pet_cycle_requested
signal mount_cycle_requested

enum PopupMode {
    NONE,
    CHARACTER,
    INVENTORY,
    SKILLS,
    PET,
    MOUNT,
}

@onready var _map_viewport: Control = $Root/CenterLayer/MapPanel/Margin/MapViewport
@onready var _player_name_value: Label = $Root/TopBar/Margin/HBox/PlayerNameValue
@onready var _hp_value: Label = $Root/TopBar/Margin/HBox/HpValue
@onready var _attack_value: Label = $Root/TopBar/Margin/HBox/AttackValue
@onready var _defense_value: Label = $Root/TopBar/Margin/HBox/DefenseValue
@onready var _power_value: Label = $Root/TopBar/Margin/HBox/PowerValue
@onready var _turn_value: Label = $Root/TopBar/Margin/HBox/TurnValue
@onready var _phase_value: Label = $Root/TopBar/Margin/HBox/PhaseValue
@onready var _loot_value: Label = $Root/RightPanel/Margin/VBox/LootValue
@onready var _class_row: Label = $Root/LeftPanel/Margin/VBox/Row1
@onready var _pet_row: Label = $Root/LeftPanel/Margin/VBox/Row2
@onready var _mount_row: Label = $Root/LeftPanel/Margin/VBox/Row3

@onready var _character_button: Button = $Root/BottomBar/Margin/VBox/Buttons/CharacterButton
@onready var _inventory_button: Button = $Root/BottomBar/Margin/VBox/Buttons/InventoryButton
@onready var _skills_button: Button = $Root/BottomBar/Margin/VBox/Buttons/SkillsButton
@onready var _pet_button: Button = $Root/BottomBar/Margin/VBox/Buttons/PetButton
@onready var _mount_button: Button = $Root/BottomBar/Margin/VBox/Buttons/MountButton
@onready var _dungeon_button: Button = $Root/BottomBar/Margin/VBox/Buttons/DungeonButton

@onready var _popup_panel: PanelContainer = $Root/PopupPanel
@onready var _popup_title: Label = $Root/PopupPanel/Margin/VBox/Header/PopupTitle
@onready var _popup_body: RichTextLabel = $Root/PopupPanel/Margin/VBox/PopupBody
@onready var _popup_hint: Label = $Root/PopupPanel/Margin/VBox/PopupHint
@onready var _popup_close_button: Button = $Root/PopupPanel/Margin/VBox/Header/CloseButton

var _player: Node
var _popup_mode: PopupMode = PopupMode.NONE
var _inventory_shortcuts: Array[StringName] = []

func _ready() -> void:
    _character_button.pressed.connect(_open_character_popup)
    _inventory_button.pressed.connect(_open_inventory_popup)
    _skills_button.pressed.connect(_open_skills_popup)
    _pet_button.pressed.connect(_on_pet_button_pressed)
    _mount_button.pressed.connect(_on_mount_button_pressed)
    _dungeon_button.pressed.connect(_on_dungeon_button_pressed)
    _popup_close_button.pressed.connect(_close_popup)

    EventBus.player_spawned.connect(_on_player_spawned)
    EventBus.player_health_changed.connect(_on_player_health_changed)
    EventBus.player_power_changed.connect(_on_player_power_changed)
    EventBus.turn_phase_changed.connect(_on_turn_phase_changed)
    EventBus.inventory_changed.connect(_on_inventory_changed)
    EventBus.equipment_changed.connect(_on_equipment_changed)
    EventBus.pet_changed.connect(_on_pet_changed)
    EventBus.mount_changed.connect(_on_mount_changed)
    EventBus.item_picked_up.connect(_on_item_picked_up)

    _refresh_player_panel()
    _refresh_turn_panel(TurnManager.phase, TurnManager.turn_number)

func _unhandled_input(event: InputEvent) -> void:
    if event is not InputEventKey:
        return

    var key_event := event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return

    if key_event.physical_keycode == KEY_ESCAPE and _popup_panel.visible:
        _close_popup()
        get_viewport().set_input_as_handled()
        return

    if _popup_mode != PopupMode.INVENTORY:
        return

    var index := _index_from_numeric_key(key_event.physical_keycode)
    if index >= 0 and index < _inventory_shortcuts.size():
        inventory_item_requested.emit(_inventory_shortcuts[index])
        _open_inventory_popup()
        get_viewport().set_input_as_handled()
        return

    match key_event.physical_keycode:
        KEY_Q:
            inventory_unequip_requested.emit(ItemData.EquipSlot.WEAPON)
            _open_inventory_popup()
            get_viewport().set_input_as_handled()
        KEY_E:
            inventory_unequip_requested.emit(ItemData.EquipSlot.SHIELD)
            _open_inventory_popup()
            get_viewport().set_input_as_handled()

func get_map_viewport_rect() -> Rect2:
    return _map_viewport.get_global_rect()

func _on_player_spawned(player: Node2D) -> void:
    _player = player
    _refresh_player_panel()
    _refresh_active_popup()

func _on_player_health_changed(current_health: int, max_health: int) -> void:
    _hp_value.text = "%d/%d" % [current_health, max_health]
    _refresh_active_popup()

func _on_turn_phase_changed(_previous_phase: int, new_phase: int, turn_number: int) -> void:
    _refresh_turn_panel(new_phase, turn_number)

func _on_player_power_changed(new_power_general: int) -> void:
    _power_value.text = str(new_power_general)
    _refresh_active_popup()

func _on_inventory_changed(actor_name: String, _item_id: StringName, _quantity: int) -> void:
    if not _is_player_actor(actor_name):
        return
    _refresh_player_panel()
    _refresh_active_popup()

func _on_equipment_changed(actor_name: String, _slot: int, _item_id: StringName) -> void:
    if not _is_player_actor(actor_name):
        return
    _refresh_player_panel()
    _refresh_active_popup()

func _on_pet_changed(actor_name: String, _pet_id: StringName) -> void:
    if not _is_player_actor(actor_name):
        return
    _refresh_player_panel()
    _refresh_active_popup()

func _on_mount_changed(actor_name: String, _mount_id: StringName) -> void:
    if not _is_player_actor(actor_name):
        return
    _refresh_player_panel()
    _refresh_active_popup()

func _on_item_picked_up(actor_name: String, item_name: String, quantity: int) -> void:
    if not _is_player_actor(actor_name):
        return
    _loot_value.text = "%s x%d" % [item_name, quantity]
    _refresh_active_popup()

func _refresh_player_panel() -> void:
    if not is_instance_valid(_player):
        _player_name_value.text = "-"
        _hp_value.text = "-/-"
        _attack_value.text = "-"
        _defense_value.text = "-"
        _power_value.text = "-"
        _class_row.text = "Classe: -"
        _pet_row.text = "Pet: -"
        _mount_row.text = "Montaria: -"
        return

    _player_name_value.text = _get_player_name()

    var current_health: int = 0
    var max_health: int = 0
    if "health" in _player and _player.health != null:
        current_health = _player.health.current_health
        max_health = _player.health.max_health
    _hp_value.text = "%d/%d" % [current_health, max_health]
    _attack_value.text = str(_player.attack_power) if "attack_power" in _player else "-"
    _defense_value.text = str(_player.defense_power) if "defense_power" in _player else "-"
    _power_value.text = str(_player.power_general) if "power_general" in _player else "-"
    _class_row.text = "Classe: %s" % _get_class_name()
    _pet_row.text = "Pet: %s" % _get_pet_name()
    _mount_row.text = "Montaria: %s" % _get_mount_name()

func _refresh_turn_panel(phase: int, turn_number: int) -> void:
    _turn_value.text = str(turn_number)
    _phase_value.text = _phase_to_string(phase)

func _phase_to_string(phase: int) -> String:
    match phase:
        TurnManager.Phase.PLAYER_INPUT:
            return "Jogador"
        TurnManager.Phase.RESOLVING:
            return "Resolucao"
        TurnManager.Phase.ENEMY_TURN:
            return "Inimigo"
        _:
            return "Idle"

func _is_player_actor(actor_name: String) -> bool:
    return is_instance_valid(_player) and actor_name == _get_player_name()

func _get_player_name() -> String:
    if not is_instance_valid(_player):
        return "-"
    return String(_player.display_name) if "display_name" in _player else _player.name

func _get_class_name() -> String:
    if not is_instance_valid(_player):
        return "-"
    if "class_data" in _player and _player.class_data != null:
        return String(_player.class_data.display_name)
    return "-"

func _get_pet_name() -> String:
    if not is_instance_valid(_player):
        return "-"
    if "equipped_pet" in _player and _player.equipped_pet != null:
        return String(_player.equipped_pet.display_name)
    return "-"

func _get_mount_name() -> String:
    if not is_instance_valid(_player):
        return "-"
    if "equipped_mount" in _player and _player.equipped_mount != null:
        return String(_player.equipped_mount.display_name)
    return "-"

func _open_character_popup() -> void:
    if not is_instance_valid(_player):
        _open_popup("Personagem", "Sem personagem ativo.", "-", PopupMode.CHARACTER)
        return

    var equipped_lines: PackedStringArray = []
    if "get_equipped_items" in _player:
        for item_data in _player.get_equipped_items():
            if item_data == null:
                continue
            equipped_lines.append("- %s (ATK +%d | DEF +%d)" % [String(item_data.display_name), item_data.attack_bonus, item_data.defense_bonus])
    if equipped_lines.is_empty():
        equipped_lines.append("- Nenhum item equipado.")

    var body := (
        "[b]Classe:[/b] %s\n[b]HP:[/b] %s\n[b]ATK:[/b] %s   [b]DEF:[/b] %s\n[b]Poder Geral:[/b] %s\n\n[b]Equipamentos:[/b]\n%s"
        % [
            _get_class_name(),
            _hp_value.text,
            _attack_value.text,
            _defense_value.text,
            _power_value.text,
            "\n".join(equipped_lines),
        ]
    )
    _open_popup("Personagem", body, "Painel de status e equipamentos atuais.", PopupMode.CHARACTER)

func _open_inventory_popup() -> void:
    if not is_instance_valid(_player):
        _open_popup("Inventario", "Sem personagem ativo.", "-", PopupMode.INVENTORY)
        return

    _inventory_shortcuts.clear()
    var inventory_lines: PackedStringArray = []
    var entries: Array[Dictionary] = []
    if "get_inventory_entries" in _player:
        entries = _player.get_inventory_entries()

    for index in range(entries.size()):
        var entry: Dictionary = entries[index]
        var item_data: ItemData = entry.get("data", null) as ItemData
        if item_data == null:
            continue

        var quantity: int = int(entry.get("quantity", 0))
        var tag: String = "[equip]" if item_data.is_equipment() else "[consumivel]"
        var shortcut_text: String = "-"
        if _inventory_shortcuts.size() < 9:
            _inventory_shortcuts.append(item_data.id)
            shortcut_text = str(_inventory_shortcuts.size())

        inventory_lines.append("%s) %s x%d %s" % [shortcut_text, String(item_data.display_name), quantity, tag])

    if inventory_lines.is_empty():
        inventory_lines.append("Sem itens na bolsa.")

    var body := "[b]Bolsa:[/b]\n%s" % "\n".join(inventory_lines)
    var hint := "Teclas 1-9: equipar/usar item | Q: desequipar arma | E: desequipar escudo"
    _open_popup("Inventario", body, hint, PopupMode.INVENTORY)

func _open_skills_popup() -> void:
    if not is_instance_valid(_player):
        _open_popup("Skills", "Sem personagem ativo.", "-", PopupMode.SKILLS)
        return

    var active_lines: PackedStringArray = []
    var passive_lines: PackedStringArray = []

    if "active_skills" in _player:
        for index in range(_player.active_skills.size()):
            var skill_data: SkillData = _player.active_skills[index] as SkillData
            if skill_data == null:
                continue
            active_lines.append("%d) %s (CD %d)" % [index + 1, String(skill_data.display_name), skill_data.cooldown_turns])
    if "passive_skills" in _player:
        for skill_data in _player.passive_skills:
            if skill_data == null:
                continue
            passive_lines.append("- %s" % String(skill_data.display_name))

    if active_lines.is_empty():
        active_lines.append("- Nenhuma skill ativa.")
    if passive_lines.is_empty():
        passive_lines.append("- Nenhuma passiva.")

    var body := "[b]Ativas:[/b]\n%s\n\n[b]Passivas:[/b]\n%s" % ["\n".join(active_lines), "\n".join(passive_lines)]
    _open_popup("Skills", body, "Ative em combate com as teclas 1-4.", PopupMode.SKILLS)

func _open_pet_popup() -> void:
    if not is_instance_valid(_player) or _player.equipped_pet == null:
        _open_popup("Pet", "Sem pet ativo.", "Clique no botao Pet para alternar.", PopupMode.PET)
        return

    var pet_data: PetData = _player.equipped_pet
    var body := (
        "[b]%s[/b]\n%s\n\nBonuses: ATK +%d | DEF +%d | HP +%d"
        % [
            String(pet_data.display_name),
            pet_data.passive_bonus_description,
            pet_data.passive_attack_bonus,
            pet_data.passive_defense_bonus,
            pet_data.passive_health_bonus,
        ]
    )
    _open_popup("Pet", body, "Clique no botao Pet (ou tecla P) para alternar pet.", PopupMode.PET)

func _open_mount_popup() -> void:
    if not is_instance_valid(_player) or _player.equipped_mount == null:
        _open_popup("Montaria", "Sem montaria ativa.", "Clique no botao Montaria para alternar.", PopupMode.MOUNT)
        return

    var mount_data: MountData = _player.equipped_mount
    var body := (
        "[b]%s[/b]\n%s\n\nBonuses: ATK +%d | DEF +%d | HP +%d | MOVE +%d"
        % [
            String(mount_data.display_name),
            mount_data.description,
            mount_data.attack_bonus,
            mount_data.defense_bonus,
            mount_data.health_bonus,
            mount_data.movement_speed_bonus,
        ]
    )
    _open_popup("Montaria", body, "Clique no botao Montaria (ou tecla M) para alternar montaria.", PopupMode.MOUNT)

func _open_popup(title: String, body: String, hint: String, mode: PopupMode) -> void:
    _popup_title.text = title
    _popup_body.text = body
    _popup_hint.text = hint
    _popup_mode = mode
    _popup_panel.show()

func _close_popup() -> void:
    _popup_panel.hide()
    _popup_mode = PopupMode.NONE
    _inventory_shortcuts.clear()

func _refresh_active_popup() -> void:
    if not _popup_panel.visible:
        return

    match _popup_mode:
        PopupMode.CHARACTER:
            _open_character_popup()
        PopupMode.INVENTORY:
            _open_inventory_popup()
        PopupMode.SKILLS:
            _open_skills_popup()
        PopupMode.PET:
            _open_pet_popup()
        PopupMode.MOUNT:
            _open_mount_popup()
        _:
            pass

func _index_from_numeric_key(keycode: int) -> int:
    match keycode:
        KEY_1:
            return 0
        KEY_2:
            return 1
        KEY_3:
            return 2
        KEY_4:
            return 3
        KEY_5:
            return 4
        KEY_6:
            return 5
        KEY_7:
            return 6
        KEY_8:
            return 7
        KEY_9:
            return 8
        _:
            return -1

func _on_pet_button_pressed() -> void:
    pet_cycle_requested.emit()
    _open_pet_popup()

func _on_mount_button_pressed() -> void:
    mount_cycle_requested.emit()
    _open_mount_popup()

func _on_dungeon_button_pressed() -> void:
    dungeon_requested.emit()
