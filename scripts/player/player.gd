class_name Player
extends Node2D

signal action_animation_finished

const PET_SCENE := preload("res://scenes/pets/pet.tscn")
const MOUNT_SCENE := preload("res://scenes/mounts/mount.tscn")
const ATTR_MAX_HEALTH: StringName = &"vida_max"
const ATTR_ATTACK: StringName = &"ataque"
const ATTR_DEFENSE: StringName = &"defesa"
const ATTR_DODGE: StringName = &"esquiva"
const ATTR_CRIT_CHANCE: StringName = &"critico_chance"
const ATTR_CRIT_DAMAGE: StringName = &"critico_dano"
const ATTR_ACCURACY: StringName = &"precisao"
const ATTR_ATTACK_SPEED: StringName = &"velocidade_ataque"
const ATTR_MOVE_SPEED: StringName = &"velocidade_movimento"
const ATTR_BLOCK: StringName = &"bloqueio"
const ATTR_PENETRATION: StringName = &"penetracao"
const ATTR_RESILIENCE: StringName = &"resiliencia"
const ATTR_LIFE_STEAL: StringName = &"roubo_vida"
const ATTR_TENACITY: StringName = &"tenacidade"
const ATTR_MAX_MANA: StringName = &"mana_max"
const ATTR_MANA_REGEN: StringName = &"regeneracao_mana"
const ATTR_COOLDOWN_REDUCTION: StringName = &"reducao_recarga"
const ATTR_ELEMENTAL_POWER: StringName = &"poder_elemental"
const ATTR_ELEMENTAL_RESIST: StringName = &"resistencia_elemental"
const ATTR_LUCK: StringName = &"sorte"
const DEFAULT_ATTRIBUTE_KEYS: Array[StringName] = [
    ATTR_MAX_HEALTH,
    ATTR_ATTACK,
    ATTR_DEFENSE,
    ATTR_DODGE,
    ATTR_CRIT_CHANCE,
    ATTR_CRIT_DAMAGE,
    ATTR_ACCURACY,
    ATTR_ATTACK_SPEED,
    ATTR_MOVE_SPEED,
    ATTR_BLOCK,
    ATTR_PENETRATION,
    ATTR_RESILIENCE,
    ATTR_LIFE_STEAL,
    ATTR_TENACITY,
    ATTR_MAX_MANA,
    ATTR_MANA_REGEN,
    ATTR_COOLDOWN_REDUCTION,
    ATTR_ELEMENTAL_POWER,
    ATTR_ELEMENTAL_RESIST,
    ATTR_LUCK,
]
const DEFAULT_ATTRIBUTE_VALUE: int = 20

@export var class_data: CharacterClassData:
    set(value):
        class_data = value
        if is_inside_tree():
            _update_from_class_data()

@export var display_name: StringName = &"Player"
@export var attack_power: int = 4
@export var defense_power: int = 1
var power_general: int = 0
var core_attributes: Dictionary = {}
var active_skills: Array[SkillData] = []
var passive_skills: Array[SkillData] = []
var equipped_pet: PetData
var equipped_mount: MountData

@onready var sprite: Sprite2D = $Sprite2D
@onready var grid_movement := $GridMovement
@onready var health := $Health
@onready var inventory: InventoryComponent = $Inventory
@onready var equipment: EquipmentComponent = $Equipment

var _pet_visual: Pet
var _mount_visual: Mount
var _base_sprite_position: Vector2 = Vector2.ZERO
var _base_sprite_scale: Vector2 = Vector2.ONE
var _base_pet_position: Vector2 = Vector2(14.0, -8.0)
var _base_pet_scale: Vector2 = Vector2.ONE
var _base_mount_position: Vector2 = Vector2(-10.0, 8.0)
var _base_mount_scale: Vector2 = Vector2.ONE

var _base_attack_power: int = 4
var _base_defense_power: int = 1
var _base_attributes: Dictionary = {}
var _skill_cooldowns: Dictionary = {}
var _action_sprite_state_id: int = 0

func _ready() -> void:
    _base_sprite_position = sprite.position
    _base_sprite_scale = sprite.scale
    _update_from_class_data()
    grid_movement.move_started.connect(_on_move_started)
    grid_movement.move_finished.connect(_on_move_finished)
    health.health_changed.connect(_on_health_changed)
    health.died.connect(_on_died)
    inventory.inventory_changed.connect(_on_inventory_changed)
    equipment.equipment_changed.connect(_on_equipment_changed)
    _ensure_companion_visuals()
    _sync_companion_visuals()

func _get_power_service() -> Node:
    return get_node_or_null("/root/PowerService")

func _create_default_attributes() -> Dictionary:
    var power_service: Node = _get_power_service()
    if power_service != null and power_service.has_method("create_default_attributes"):
        return power_service.call("create_default_attributes")

    var attributes: Dictionary = {}
    for key in DEFAULT_ATTRIBUTE_KEYS:
        attributes[key] = DEFAULT_ATTRIBUTE_VALUE
    return attributes

func _sanitize_attributes(raw_attributes: Dictionary) -> Dictionary:
    var power_service: Node = _get_power_service()
    if power_service != null and power_service.has_method("sanitize_attributes"):
        return power_service.call("sanitize_attributes", raw_attributes)

    var sanitized_attributes: Dictionary = _create_default_attributes()
    for key in DEFAULT_ATTRIBUTE_KEYS:
        if raw_attributes.has(key):
            sanitized_attributes[key] = maxi(int(raw_attributes[key]), 0)
    return sanitized_attributes

func _calculate_power_general(attributes: Dictionary) -> int:
    var power_service: Node = _get_power_service()
    if power_service != null and power_service.has_method("calculate_power_general"):
        return int(power_service.call("calculate_power_general", attributes))

    var fallback_power: int = 0
    for key in attributes.keys():
        fallback_power += int(attributes[key])
    return maxi(fallback_power, 1)

func _update_from_class_data() -> void:
    if class_data:
        display_name = class_data.display_name
        _base_attack_power = class_data.base_attack
        _base_defense_power = class_data.base_defense
        _base_attributes = _sanitize_attributes(class_data.get_base_attributes())
        _load_class_skills()
        if is_instance_valid(health):
            health.max_health = class_data.base_max_health
            health.current_health = class_data.base_max_health
    else:
        _base_attributes = _create_default_attributes()
        active_skills.clear()
        passive_skills.clear()
        _skill_cooldowns.clear()
    _recalculate_combat_stats()
    if is_instance_valid(health):
        health.current_health = health.max_health
        health.health_changed.emit(health.current_health, health.max_health)
    _reset_action_sprite()

func _update_sprite_texture() -> void:
    if not is_instance_valid(sprite):
        return

    if class_data and class_data.idle_sprite:
        sprite.texture = class_data.idle_sprite

func _reset_action_sprite() -> void:
    _action_sprite_state_id += 1
    _update_sprite_texture()

func _set_temporary_action_sprite(action_sprite: Texture2D, duration: float) -> void:
    if action_sprite == null or not is_instance_valid(sprite):
        return

    _action_sprite_state_id += 1
    var action_state_id: int = _action_sprite_state_id
    sprite.texture = action_sprite

    var timer := get_tree().create_timer(maxf(duration, 0.0))
    timer.timeout.connect(func() -> void:
        if action_state_id != _action_sprite_state_id:
            return
        _update_sprite_texture()
    )

func set_grid_position(cell: Vector2i) -> void:
    grid_movement.grid_position = cell
    grid_movement.snap_to_grid()

func get_grid_position() -> Vector2i:
    return grid_movement.grid_position

func try_move_direction(direction: Vector2i, is_cell_blocked: Callable) -> bool:
    return grid_movement.try_move(direction, is_cell_blocked)

func is_alive() -> bool:
    return health.current_health > 0

func take_damage(amount: int) -> int:
    var mitigated_amount: int = maxi(1, amount - defense_power)
    var applied_damage: int = health.take_damage(mitigated_amount)
    if applied_damage > 0:
        _play_hit_animation()
        EventBus.actor_damaged.emit(display_name, applied_damage, health.current_health, health.max_health)
    return applied_damage

func try_attack(target: Node) -> bool:
    if target == null or not target.has_method("take_damage"):
        return false

    var applied_damage: int = target.take_damage(attack_power)
    if applied_damage <= 0:
        return false

    _play_attack_animation()
    var target_name: String = target.display_name if "display_name" in target else target.name
    EventBus.actor_attacked.emit(display_name, target_name, applied_damage)
    EventBus.action_resolved.emit(display_name, &"attack")
    action_animation_finished.emit()
    return true

func add_item(item_data: ItemData, amount: int = 1) -> bool:
    var added: bool = inventory.add_item(item_data, amount)
    if added:
        _try_auto_equip_item(item_data)
        _recalculate_combat_stats()
    return added

func get_item_quantity(item_id: StringName) -> int:
    return inventory.get_quantity(item_id)

func has_item(item_id: StringName, amount: int = 1) -> bool:
    return inventory.has_item(item_id, amount)

func get_inventory_entries() -> Array[Dictionary]:
    return inventory.get_entries()

func get_equipped_items() -> Array[ItemData]:
    return equipment.get_equipped_items()

func try_equip_item_by_id(item_id: StringName) -> bool:
    if class_data == null:
        return false
    if not inventory.has_item(item_id):
        return false

    var item_data: ItemData = inventory.get_item_data(item_id)
    if item_data == null:
        return false
    if not item_data.is_equipment():
        return false

    return equipment.equip(item_data, class_data.id)

func try_unequip_slot(slot: int) -> bool:
    var unequipped_item: ItemData = equipment.unequip(slot)
    return unequipped_item != null

func equip_pet(pet_data: PetData) -> void:
    equipped_pet = pet_data
    _sync_companion_visuals()
    _recalculate_combat_stats()
    var pet_id: StringName = pet_data.id if pet_data != null else &""
    EventBus.pet_changed.emit(display_name, pet_id)

func equip_mount(mount_data: MountData) -> void:
    equipped_mount = mount_data
    _sync_companion_visuals()
    _recalculate_combat_stats()
    var mount_id: StringName = mount_data.id if mount_data != null else &""
    EventBus.mount_changed.emit(display_name, mount_id)

func on_new_player_turn() -> void:
    var updated_cooldowns: Dictionary = {}
    for skill_id in _skill_cooldowns.keys():
        var remaining_turns: int = maxi(int(_skill_cooldowns[skill_id]) - 1, 0)
        if remaining_turns > 0:
            updated_cooldowns[skill_id] = remaining_turns
    _skill_cooldowns = updated_cooldowns

func try_use_active_skill_slot(slot_index: int, target: Node = null) -> bool:
    if slot_index < 0 or slot_index >= active_skills.size():
        return false

    var skill_data: SkillData = active_skills[slot_index]
    if skill_data == null or not skill_data.is_active():
        return false
    if _get_skill_cooldown(skill_data.id) > 0:
        return false

    if skill_data.requires_enemy_target:
        if target == null or not target.has_method("take_damage"):
            return false

        var raw_damage: int = int(round(attack_power * skill_data.power_multiplier)) + skill_data.flat_damage_bonus
        var applied_damage: int = target.take_damage(maxi(raw_damage, 1))
        if applied_damage <= 0:
            return false

        var target_name: String = target.display_name if "display_name" in target else target.name
        EventBus.actor_attacked.emit(display_name, target_name, applied_damage)

    _skill_cooldowns[skill_data.id] = maxi(skill_data.cooldown_turns, 0)
    _play_skill_animation()
    EventBus.skill_used.emit(display_name, skill_data.id, String(skill_data.display_name))
    EventBus.action_resolved.emit(display_name, &"skill")
    action_animation_finished.emit()
    return true

func try_use_consumable(item_id: StringName) -> bool:
    var item_data: ItemData = inventory.get_item_data(item_id)
    if item_data == null:
        return false
    if item_data.item_kind != ItemData.ItemKind.CONSUMABLE:
        return false

    var applied_heal: int = 0
    if item_data.heal_amount > 0:
        applied_heal = health.heal(item_data.heal_amount)
        if applied_heal <= 0:
            return false

    var consumed_item: ItemData = inventory.consume_item(item_id, 1)
    if consumed_item == null:
        return false
    _recalculate_combat_stats()

    EventBus.item_used.emit(display_name, consumed_item.display_name, 1)
    EventBus.action_resolved.emit(display_name, &"use_item")
    action_animation_finished.emit()
    return true

func _on_move_finished(_new_cell: Vector2i) -> void:
    EventBus.action_resolved.emit(display_name, &"move")
    action_animation_finished.emit()

func _on_move_started(_from_cell: Vector2i, _to_cell: Vector2i) -> void:
    _play_walk_animation()

func _on_health_changed(current_health: int, max_health: int) -> void:
    EventBus.player_health_changed.emit(current_health, max_health)

func _on_inventory_changed(item_id: StringName, quantity: int) -> void:
    EventBus.inventory_changed.emit(display_name, item_id, quantity)

func _on_equipment_changed(slot: int, item_data: ItemData) -> void:
    var item_id: StringName = item_data.id if item_data != null else &""
    EventBus.equipment_changed.emit(display_name, slot, item_id)
    _recalculate_combat_stats()

func _on_died() -> void:
    EventBus.player_died.emit()

func _recalculate_combat_stats() -> void:
    var total_attack_bonus: int = 0
    var total_defense_bonus: int = 0
    var passive_attack_bonus: int = 0
    var passive_defense_bonus: int = 0
    var passive_health_bonus: int = 0
    var pet_attack_bonus: int = 0
    var pet_defense_bonus: int = 0
    var pet_health_bonus: int = 0
    var mount_attack_bonus: int = 0
    var mount_defense_bonus: int = 0
    var mount_health_bonus: int = 0
    var mount_speed_bonus: int = 0

    for item_data in equipment.get_equipped_items():
        if item_data == null:
            continue
        total_attack_bonus += item_data.attack_bonus
        total_defense_bonus += item_data.defense_bonus

    for skill_data in passive_skills:
        if skill_data == null:
            continue
        passive_attack_bonus += skill_data.passive_attack_bonus
        passive_defense_bonus += skill_data.passive_defense_bonus
        passive_health_bonus += skill_data.passive_health_bonus

    if equipped_pet != null:
        pet_attack_bonus = equipped_pet.passive_attack_bonus
        pet_defense_bonus = equipped_pet.passive_defense_bonus
        pet_health_bonus = equipped_pet.passive_health_bonus

    if equipped_mount != null:
        mount_attack_bonus = equipped_mount.attack_bonus
        mount_defense_bonus = equipped_mount.defense_bonus
        mount_health_bonus = equipped_mount.health_bonus
        mount_speed_bonus = equipped_mount.movement_speed_bonus

    core_attributes = _base_attributes.duplicate(true)
    core_attributes[ATTR_ATTACK] = int(core_attributes.get(ATTR_ATTACK, DEFAULT_ATTRIBUTE_VALUE)) + total_attack_bonus + passive_attack_bonus + pet_attack_bonus + mount_attack_bonus
    core_attributes[ATTR_DEFENSE] = int(core_attributes.get(ATTR_DEFENSE, DEFAULT_ATTRIBUTE_VALUE)) + total_defense_bonus + passive_defense_bonus + pet_defense_bonus + mount_defense_bonus
    core_attributes[ATTR_MAX_HEALTH] = int(core_attributes.get(ATTR_MAX_HEALTH, DEFAULT_ATTRIBUTE_VALUE)) + passive_health_bonus + pet_health_bonus + mount_health_bonus
    core_attributes[ATTR_MOVE_SPEED] = int(core_attributes.get(ATTR_MOVE_SPEED, DEFAULT_ATTRIBUTE_VALUE)) + mount_speed_bonus

    attack_power = _base_attack_power + total_attack_bonus + passive_attack_bonus + pet_attack_bonus + mount_attack_bonus
    defense_power = _base_defense_power + total_defense_bonus + passive_defense_bonus + pet_defense_bonus + mount_defense_bonus

    if is_instance_valid(health):
        var previous_health: int = health.current_health
        var base_health_limit: int = class_data.base_max_health if class_data != null else 20
        health.max_health = base_health_limit + passive_health_bonus + pet_health_bonus + mount_health_bonus
        health.current_health = mini(previous_health, health.max_health)

    if is_instance_valid(grid_movement):
        var movement_score: int = int(core_attributes.get(ATTR_MOVE_SPEED, DEFAULT_ATTRIBUTE_VALUE))
        grid_movement.move_duration = clampf(0.10 - float(movement_score - 20) * 0.003, 0.04, 0.12)

    power_general = _calculate_power_general(core_attributes)
    EventBus.player_power_changed.emit(power_general)

func _load_class_skills() -> void:
    active_skills.clear()
    passive_skills.clear()
    _skill_cooldowns.clear()

    if class_data == null:
        return

    for skill_id in class_data.active_skill_ids:
        var skill_data: SkillData = _load_skill_resource(skill_id)
        if skill_data != null and skill_data.is_active():
            active_skills.append(skill_data)

    for skill_id in class_data.passive_skill_ids:
        var skill_data: SkillData = _load_skill_resource(skill_id)
        if skill_data != null and skill_data.is_passive():
            passive_skills.append(skill_data)

func _load_skill_resource(skill_id: StringName) -> SkillData:
    if skill_id.is_empty():
        return null

    var resource_path: String = "res://data/skills/%s.tres" % String(skill_id)
    if not ResourceLoader.exists(resource_path):
        return null

    return load(resource_path) as SkillData

func _get_skill_cooldown(skill_id: StringName) -> int:
    return int(_skill_cooldowns.get(skill_id, 0))

func _try_auto_equip_item(item_data: ItemData) -> void:
    if item_data == null or not item_data.is_equipment() or class_data == null:
        return
    equipment.equip(item_data, class_data.id)

func _ensure_companion_visuals() -> void:
    if _mount_visual == null:
        _mount_visual = MOUNT_SCENE.instantiate() as Mount
        if _mount_visual != null:
            _mount_visual.name = "MountVisual"
            _mount_visual.z_index = -1
            _mount_visual.position = _base_mount_position
            _mount_visual.scale = Vector2(0.92, 0.92)
            _base_mount_scale = _mount_visual.scale
            add_child(_mount_visual)

    if _pet_visual == null:
        _pet_visual = PET_SCENE.instantiate() as Pet
        if _pet_visual != null:
            _pet_visual.name = "PetVisual"
            _pet_visual.z_index = 1
            _pet_visual.position = _base_pet_position
            _pet_visual.scale = Vector2(0.85, 0.85)
            _base_pet_scale = _pet_visual.scale
            add_child(_pet_visual)

func _sync_companion_visuals() -> void:
    if _pet_visual != null:
        _pet_visual.pet_data = equipped_pet
        _pet_visual.visible = equipped_pet != null
        _pet_visual.position = _base_pet_position
    if _mount_visual != null:
        _mount_visual.mount_data = equipped_mount
        _mount_visual.visible = equipped_mount != null
        _mount_visual.position = _base_mount_position

func _play_walk_animation() -> void:
    if class_data and class_data.walk_sprite:
        _set_temporary_action_sprite(class_data.walk_sprite, 0.08)
    _animate_position_bob(sprite, _base_sprite_position, Vector2(0.0, -2.0), 0.08)
    _animate_scale_pulse(sprite, _base_sprite_scale, Vector2(1.04, 0.96), 0.08)

    if _pet_visual != null and _pet_visual.visible:
        _pet_visual.play_walk_animation(0.08)
        _animate_position_bob(_pet_visual, _base_pet_position, Vector2(0.0, -1.0), 0.08)
    if _mount_visual != null and _mount_visual.visible:
        _mount_visual.play_run_animation(0.08)
        _animate_position_bob(_mount_visual, _base_mount_position, Vector2(0.0, -1.0), 0.08)

func _play_attack_animation() -> void:
    if class_data and class_data.attack_sprite:
        _set_temporary_action_sprite(class_data.attack_sprite, 0.08)
    _animate_position_bob(sprite, _base_sprite_position, Vector2(2.5, 0.0), 0.08)
    _animate_scale_pulse(sprite, _base_sprite_scale, Vector2(1.08, 0.92), 0.08)
    if _pet_visual != null and _pet_visual.visible:
        _pet_visual.play_attack_animation(0.08)
        _animate_position_bob(_pet_visual, _base_pet_position, Vector2(1.5, -0.5), 0.08)
    if _mount_visual != null and _mount_visual.visible:
        _mount_visual.play_run_animation(0.08)
        _animate_position_bob(_mount_visual, _base_mount_position, Vector2(1.0, -0.5), 0.08)

func _play_skill_animation() -> void:
    _animate_position_bob(sprite, _base_sprite_position, Vector2(0.0, -3.0), 0.10)
    _animate_scale_pulse(sprite, _base_sprite_scale, Vector2(1.1, 0.9), 0.10)

func _play_hit_animation() -> void:
    if class_data and class_data.hit_sprite:
        _set_temporary_action_sprite(class_data.hit_sprite, 0.06)
    _animate_scale_pulse(sprite, _base_sprite_scale, Vector2(0.92, 1.08), 0.06)

func _animate_position_bob(node: Node2D, base_position: Vector2, peak_offset: Vector2, duration: float) -> void:
    if node == null:
        return
    node.position = base_position
    var tween := create_tween()
    tween.tween_property(node, "position", base_position + peak_offset, duration * 0.5)
    tween.tween_property(node, "position", base_position, duration * 0.5)

func _animate_scale_pulse(node: Node2D, base_scale: Vector2, pulse_scale: Vector2, duration: float) -> void:
    if node == null:
        return
    node.scale = base_scale
    var tween := create_tween()
    tween.tween_property(node, "scale", Vector2(base_scale.x * pulse_scale.x, base_scale.y * pulse_scale.y), duration * 0.5)
    tween.tween_property(node, "scale", base_scale, duration * 0.5)
