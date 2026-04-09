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
@export var grants_pet_id: StringName

func can_stack() -> bool:
    return stackable and max_stack > 1

func is_equipment() -> bool:
    return item_kind == ItemKind.WEAPON or item_kind == ItemKind.ARMOR

