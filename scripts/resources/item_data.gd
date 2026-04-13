class_name ItemData
extends Resource

enum ItemKind {
    CONSUMABLE,
    WEAPON,
    ARMOR,
    KEY_ITEM,
    PET_TOKEN,
}

enum Rarity {
    COMMON,
    UNCOMMON,
    RARE,
    EPIC,
    LEGENDARY,
}

enum EquipSlot {
    NONE,
    HELMET,
    ARMOR,
    GLOVES,
    BOOTS,
    SHIELD,
    WEAPON,
}

@export var id: StringName
@export var display_name: StringName
@export_multiline var description: String
@export var icon: Texture2D

@export_group("Classification")
@export var item_kind: ItemKind = ItemKind.CONSUMABLE
@export var rarity: Rarity = Rarity.COMMON
@export var tags: Array[StringName] = []

@export_group("Inventory")
@export var stackable: bool = false
@export var max_stack: int = 1

@export_group("Effects")
@export var heal_amount: int = 0
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var critical_chance: float = 0.0 # 0.0 to 1.0 (e.g. 0.05 = 5%)
@export var critical_damage: float = 0.0 # extra critical multiplier (e.g. 0.5 = +50% dmg)
@export var lifesteal_percent: float = 0.0 # percentage of dmg returned as health (e.g. 0.1 = 10%)
@export var grants_pet_id: StringName

@export_group("Equipment")
@export var equip_slot: EquipSlot = EquipSlot.NONE
@export var allowed_class_ids: Array[StringName] = []

func can_stack() -> bool:
    return stackable and max_stack > 1

func is_equipment() -> bool:
    return item_kind == ItemKind.WEAPON or item_kind == ItemKind.ARMOR

func is_class_allowed(class_id: StringName) -> bool:
    if allowed_class_ids.is_empty():
        return true
    return class_id in allowed_class_ids

func generate_instance() -> ItemData:
    var new_item: ItemData = self.duplicate() as ItemData
    if new_item.can_stack():
        return new_item

    # unique id for gacha logic
    new_item.id = StringName(str(self.id) + "_" + str(randi()))

    match new_item.rarity:
        Rarity.UNCOMMON:
            new_item.attack_bonus += randi_range(1, 3)
            new_item.critical_chance += randf_range(0.01, 0.04)
        Rarity.RARE:
            new_item.attack_bonus += randi_range(2, 5)
            new_item.defense_bonus += randi_range(1, 3)
            new_item.critical_chance += randf_range(0.05, 0.10)
        Rarity.EPIC:
            new_item.attack_bonus += randi_range(4, 8)
            new_item.defense_bonus += randi_range(2, 5)
            new_item.critical_chance += randf_range(0.10, 0.15)
            new_item.critical_damage += randf_range(0.2, 0.5)
        Rarity.LEGENDARY:
            new_item.attack_bonus += randi_range(6, 12)
            new_item.defense_bonus += randi_range(4, 8)
            new_item.critical_chance += randf_range(0.15, 0.25)
            new_item.critical_damage += randf_range(0.5, 1.0)
            new_item.lifesteal_percent += randf_range(0.05, 0.15)

    return new_item
